# Hot Reload System Design

Måne3D のフルホットリロードシステムの要件定義・設計ドキュメント。

## 1. 現状分析

### 1.1 既存実装

| コンポーネント | ファイル | 機能 |
|---------------|---------|------|
| hotreload.lua | `lib/hotreload.lua` | requireフック、mtime監視、モジュールリロード |
| render_pipeline.lua | `lib/render_pipeline.lua` | pcallでパス実行をラップ、エラー回復 |
| render_pass.lua | `lib/render_pass.lua` | `on_reload`フックでシェーダー/パイプライン再生成 |
| gpu.lua | `lib/gpu.lua` | GCベースのGPUリソース管理 |

### 1.2 現状の制限

1. **モジュールリロード**: `lume.hotswap`依存（現在deps未追加）
2. **アセットリロード**: テクスチャ・モデルの監視未実装
3. **エントリーポイント**: `init/frame/event/cleanup`関数のリロード困難
4. **状態復旧**: クラッシュ後の状態復元機構なし
5. **グローバル状態**: モジュールローカル変数がリロード時に失われる

---

## 2. 要件定義

### 2.1 機能要件

#### FR-1: スクリプトホットリロード

| ID | 要件 | 優先度 |
|----|------|--------|
| FR-1.1 | Luaモジュール変更時の自動リロード | Must |
| FR-1.2 | シェーダーソース変更時の再コンパイル | Must |
| FR-1.3 | エントリーポイント関数の差し替え | Should |
| FR-1.4 | 循環依存のある複数モジュールの一括リロード | Could |

#### FR-2: アセットホットリロード

| ID | 要件 | 優先度 |
|----|------|--------|
| FR-2.1 | テクスチャファイル変更時の再読み込み | Must |
| FR-2.2 | モデルデータ（.lua/.luac）変更時の再読み込み | Should |
| FR-2.3 | 音声ファイル変更時の再読み込み | Could |
| FR-2.4 | アセット依存関係の追跡（テクスチャを使うメッシュ等） | Should |

#### FR-3: エラー回復

| ID | 要件 | 優先度 |
|----|------|--------|
| FR-3.1 | Luaエラー時のフレームループ継続 | Must |
| FR-3.2 | シェーダーコンパイルエラー時のフォールバック | Must |
| FR-3.3 | クラッシュ時の最終正常状態へのロールバック | Should |
| FR-3.4 | ユーザーへのエラー通知（画面表示） | Must |

#### FR-4: 状態管理

| ID | 要件 | 優先度 |
|----|------|--------|
| FR-4.1 | リロード時の重要状態（カメラ位置等）保持 | Must |
| FR-4.2 | GPUリソースの安全な解放・再生成 | Must |
| FR-4.3 | 状態のスナップショット・復元 | Could |

### 2.2 非機能要件

| ID | 要件 | 目標値 |
|----|------|--------|
| NFR-1 | リロード検出レイテンシ | < 500ms |
| NFR-2 | リロード処理時間（単一モジュール） | < 100ms |
| NFR-3 | テクスチャリロード時間（1024x1024） | < 500ms |
| NFR-4 | メモリオーバーヘッド | < 10MB |
| NFR-5 | フレームレート影響（監視処理） | < 1ms/frame |

---

## 3. アーキテクチャ設計

### 3.1 コンポーネント図

```
┌─────────────────────────────────────────────────────────────────┐
│                        Application                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐│
│  │  init()  │  │ frame()  │  │ event()  │  │    cleanup()     ││
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┬─────────┘│
│       │             │             │                  │          │
└───────┼─────────────┼─────────────┼──────────────────┼──────────┘
        │             │             │                  │
        ▼             ▼             ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Hot Reload Controller                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Reload Scheduler                      │   │
│  │  - バッチ処理（同一フレーム内の複数変更を統合）          │   │
│  │  - 優先度制御（シェーダー > モジュール > アセット）      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌───────────────┬───────────┴───────────┬───────────────────┐ │
│  ▼               ▼                       ▼                   │ │
│  ┌───────────┐  ┌───────────────┐  ┌───────────────┐         │ │
│  │  Script   │  │    Asset      │  │    State      │         │ │
│  │  Reloader │  │   Reloader    │  │   Manager     │         │ │
│  └───────────┘  └───────────────┘  └───────────────┘         │ │
└─────────────────────────────────────────────────────────────────┘
        │                 │                   │
        ▼                 ▼                   ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────────────────┐
│  File Watcher │ │  Asset Cache  │ │    State Snapshots        │
│  (mtime監視)  │ │  (参照カウント)│ │  (シリアライズ可能状態)   │
└───────────────┘ └───────────────┘ └───────────────────────────┘
```

### 3.2 クラス設計

#### 3.2.1 HotReloadController

```lua
---@class HotReloadController
---@field watchers FileWatcher[]
---@field script_reloader ScriptReloader
---@field asset_reloader AssetReloader
---@field state_manager StateManager
---@field pending_reloads table<string, ReloadRequest>
local HotReloadController = {}

---フレーム毎に呼び出し
function HotReloadController:update()
    -- 1. ファイル変更チェック（throttle付き）
    -- 2. 変更をバッチ処理キューに追加
    -- 3. 依存関係を解決してリロード順序決定
    -- 4. リロード実行
end

---強制リロード（デバッグ用）
---@param path string
function HotReloadController:force_reload(path) end
```

#### 3.2.2 ScriptReloader

```lua
---@class ScriptReloader
---@field module_cache table<string, ModuleInfo>
local ScriptReloader = {}

---@class ModuleInfo
---@field path string ファイルパス
---@field modname string モジュール名
---@field mtime number 最終更新時刻
---@field deps string[] 依存モジュール
---@field dependents string[] 被依存モジュール

---モジュールをリロード
---@param modname string
---@return boolean success
---@return string? error
function ScriptReloader:reload(modname)
    -- 1. 現在のモジュールをアンロード
    -- 2. 新しいコードをロード（loadfile + pcall）
    -- 3. on_reload フック呼び出し
    -- 4. 失敗時は古いモジュールを復元
end

---ホットスワップ（lume.hotswap相当の自前実装）
---@param modname string
---@return table? module
---@return string? error
function ScriptReloader:hotswap(modname)
    local oldmod = package.loaded[modname]
    package.loaded[modname] = nil

    local ok, newmod = pcall(require, modname)
    if not ok then
        package.loaded[modname] = oldmod
        return nil, newmod
    end

    -- テーブルの中身を入れ替え（参照を保持）
    if type(oldmod) == "table" and type(newmod) == "table" then
        for k in pairs(oldmod) do oldmod[k] = nil end
        for k, v in pairs(newmod) do oldmod[k] = v end
        package.loaded[modname] = oldmod
        return oldmod, nil
    end

    return newmod, nil
end
```

#### 3.2.3 AssetReloader

```lua
---@class AssetReloader
---@field textures table<string, TextureHandle>
---@field models table<string, ModelHandle>
local AssetReloader = {}

---@class TextureHandle
---@field path string
---@field mtime number
---@field gpu_resource gpu.Image
---@field gpu_view gpu.View
---@field users table[] 参照しているオブジェクト

---テクスチャをリロード
---@param path string
function AssetReloader:reload_texture(path)
    local handle = self.textures[path]
    if not handle then return end

    -- 1. 新しいテクスチャをロード（旧リソースは保持）
    -- 2. 成功したら旧リソースを破棄、ハンドルを更新
    -- 3. 全ユーザーに通知
end

---アセット参照を登録
---@param path string
---@param user table
function AssetReloader:register_user(path, user) end
```

#### 3.2.4 StateManager

```lua
---@class StateManager
---@field snapshots table<string, StateSnapshot>
---@field persistent_keys string[] 保持すべき状態キー
local StateManager = {}

---@class StateSnapshot
---@field timestamp number
---@field data table シリアライズされた状態

---状態のスナップショットを作成
---@param key string
---@param state table
function StateManager:snapshot(key, state)
    -- シリアライズ可能な部分のみ保存
    self.snapshots[key] = {
        timestamp = os.clock(),
        data = self:serialize(state)
    }
end

---状態を復元
---@param key string
---@return table?
function StateManager:restore(key)
    local snap = self.snapshots[key]
    if snap then
        return self:deserialize(snap.data)
    end
end

---保持すべき状態を宣言
---@param keys string[]
function StateManager:persist(keys)
    self.persistent_keys = keys
end
```

### 3.3 エラー回復フロー

```
                    ┌──────────────┐
                    │  frame()呼出 │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │ pcall実行    │
                    └──────┬───────┘
                           │
              ┌────────────┴────────────┐
              │                         │
       成功   ▼                  失敗   ▼
    ┌─────────────┐          ┌─────────────────┐
    │ 正常続行     │          │ エラーログ出力  │
    │ スナップ保存 │          │ notify表示      │
    └─────────────┘          └────────┬────────┘
                                      │
                              ┌───────▼────────┐
                              │ 3連続失敗?     │
                              └───────┬────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
             No     ▼                            Yes    ▼
         ┌─────────────┐                    ┌─────────────────┐
         │ 次フレーム  │                    │ 最終正常状態    │
         │ で再試行    │                    │ へロールバック  │
         └─────────────┘                    └─────────────────┘
                                                    │
                                            ┌───────▼────────┐
                                            │ リロード強制   │
                                            │ 実行           │
                                            └────────────────┘
```

---

## 4. 詳細設計

### 4.1 ファイル監視

```lua
---@class FileWatcher
local FileWatcher = {}

-- 監視対象の追加
function FileWatcher:watch(path, callback)
    self.watched[path] = {
        mtime = get_mtime(path),
        callback = callback
    }
end

-- 変更チェック（throttle付き）
function FileWatcher:poll()
    local now = os.clock()
    if now - self.last_poll < self.interval then return end
    self.last_poll = now

    local changes = {}
    for path, info in pairs(self.watched) do
        local mtime = get_mtime(path)
        if mtime > 0 and mtime ~= info.mtime then
            info.mtime = mtime
            table.insert(changes, { path = path, callback = info.callback })
        end
    end

    return changes
end
```

### 4.2 依存関係解決

```lua
---モジュール依存関係を解析
---@param modname string
---@return string[] dependencies
local function analyze_dependencies(modname)
    local path = resolve_path(modname)
    if not path then return {} end

    local content = read_file(path)
    local deps = {}

    -- require("...") パターンを検出
    for dep in content:gmatch('require%s*%(?%s*["\']([^"\']+)["\']') do
        -- 標準ライブラリ・Cモジュールは除外
        if not is_builtin(dep) then
            table.insert(deps, dep)
        end
    end

    return deps
end

---トポロジカルソートでリロード順序を決定
---@param changed string[] 変更されたモジュール
---@return string[] reload_order
local function compute_reload_order(changed)
    -- 変更モジュールとその被依存モジュールを収集
    -- トポロジカルソートで順序決定
    -- 循環依存は警告して同時リロード
end
```

### 4.3 エントリーポイントリロード

エントリーポイント（`init/frame/event/cleanup`）のリロードは特別な処理が必要：

```lua
---@class EntryPointManager
local EntryPointManager = {}

-- グローバル関数をラップ
function EntryPointManager:setup()
    local real = {
        init = _G.init,
        frame = _G.frame,
        event = _G.event,
        cleanup = _G.cleanup
    }

    _G.frame = function()
        -- エラーハンドリング付きで実行
        local ok, err = pcall(real.frame)
        if not ok then
            self:handle_error("frame", err)
        end
    end

    -- リロード時に差し替え
    function self:reload_entry(name, fn)
        real[name] = fn
    end
end
```

### 4.4 GPU リソース安全解放

```lua
---リソース解放を次フレームに遅延
---@param resource gpu.Resource
local function defer_destroy(resource)
    -- GPU が使用中の可能性があるため1フレーム遅延
    table.insert(pending_destroys, {
        resource = resource,
        frame = current_frame + 1
    })
end

-- フレーム開始時に実行
local function flush_pending_destroys()
    local i = 1
    while i <= #pending_destroys do
        local item = pending_destroys[i]
        if item.frame <= current_frame then
            item.resource:destroy()
            table.remove(pending_destroys, i)
        else
            i = i + 1
        end
    end
end
```

---

## 5. API 設計

### 5.1 ユーザー向けAPI

```lua
local hotreload = require("lib.hotreload")

-- 基本設定
hotreload.enabled = true
hotreload.interval = 0.5  -- 秒

-- 状態保持の宣言
hotreload.persist({
    "camera.pos",
    "camera.yaw",
    "camera.pitch",
    "light.sources"
})

-- リロードフック
function M.on_reload()
    -- リソース再生成処理
end

function M.on_before_reload()
    -- 状態保存処理（オプション）
end

-- 手動リロード
hotreload.reload("examples.rendering.geometry")
hotreload.reload_all()  -- 全監視ファイルをリロード

-- フレーム毎に呼び出し
function frame()
    hotreload.update()
    -- ...
end
```

### 5.2 アセット向けAPI

```lua
local asset = require("lib.asset")

-- テクスチャ読み込み（自動監視）
local tex = asset.texture("assets/scene/tex/diffuse.png", {
    hot_reload = true  -- デフォルトtrue
})

-- リロードコールバック
tex:on_reload(function(new_tex)
    -- 参照更新処理
end)

-- モデル読み込み
local model = asset.model("assets/scene/model.lua", {
    hot_reload = true
})
```

---

## 6. 実装計画

### Phase 1: 基盤整備（Must）

1. `lume.hotswap`相当の自前実装
2. 依存関係追跡の実装
3. エラー回復の強化（連続失敗検出、ロールバック）

### Phase 2: アセットリロード（Must）

1. テクスチャ監視・リロード
2. アセットキャッシュの参照カウント管理
3. GPU リソースの遅延解放

### Phase 3: 状態管理（Should）

1. 状態スナップショット機構
2. シリアライズ/デシリアライズ
3. 永続化キーの宣言的API

### Phase 4: 高度な機能（Could）

1. エントリーポイントのホットリロード
2. 循環依存の自動解決
3. ファイル変更のバッチ処理最適化

---

## 7. テスト計画

### 7.1 単体テスト

| テストケース | 検証内容 |
|-------------|---------|
| モジュールリロード | 正常リロード、構文エラー、実行時エラー |
| 依存関係解決 | 単純依存、多段依存、循環依存 |
| 状態復元 | プリミティブ、テーブル、ネスト |

### 7.2 統合テスト

| テストケース | 検証内容 |
|-------------|---------|
| シェーダーリロード | コンパイルエラー時のフォールバック |
| テクスチャリロード | 異なるサイズ、フォーマット変更 |
| 連続リロード | 高頻度変更時の安定性 |

### 7.3 エッジケース

- リロード中のリロード要求
- 監視中ファイルの削除
- 巨大ファイルのリロード
- ネットワークドライブ上のファイル

---

## 8. 参考資料

- [Sokol lifecycle](https://github.com/floooh/sokol)
- [Lua module system](https://www.lua.org/manual/5.4/manual.html#6.3)
- [rxi/lume hotswap](https://github.com/rxi/lume)
