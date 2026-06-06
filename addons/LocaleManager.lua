local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local LocaleManager = {
    Library = nil,
    Locale = "en",
    Dictionaries = {
        en = {
            ["locale.language"] = "Language",
            ["locale.english"] = "English",
            ["locale.japanese"] = "Japanese",
            ["manager.interface.appearance"] = "Interface",
            ["manager.interface.utility"] = "Utility",
            ["manager.interface.server"] = "Server",
            ["manager.interface.auto_minimize"] = "Auto minimize",
            ["manager.interface.auto_execute"] = "Auto execute",
            ["manager.interface.anti_afk"] = "Anti AFK",
            ["manager.interface.performance"] = "Ultra Performance Mode",
            ["manager.interface.fps_cap"] = "FPS Cap",
            ["manager.interface.auto_rejoin"] = "Auto rejoin",
            ["manager.interface.low_player_hop"] = "Low player hop",
            ["manager.interface.anti_stuck_hop"] = "Anti stuck hop",
            ["manager.interface.anti_stuck_seconds"] = "Anti stuck seconds",
            ["manager.interface.anti_stuck_disabled"] = "Anti stuck hop: disabled",
            ["manager.interface.anti_stuck_disabled_delay"] = "Anti stuck hop: disabled (delay: {time})",
            ["manager.interface.anti_stuck_remaining"] = "Anti stuck hop: {time} remaining",
            ["manager.interface.staff_detector"] = "Staff detector",
            ["manager.interface.webhook_url"] = "Discord webhook URL",
            ["manager.interface.server_hop"] = "Server hop",
            ["manager.save.configuration"] = "Configuration",
            ["manager.save.config_name"] = "Config name",
            ["manager.save.create"] = "Create config",
            ["manager.save.config_list"] = "Config list",
            ["manager.save.load"] = "Load config",
            ["manager.save.overwrite"] = "Overwrite config",
            ["manager.save.delete"] = "Delete config",
            ["manager.save.refresh"] = "Refresh list",
            ["manager.save.set_autoload"] = "Set as autoload",
            ["manager.save.reset_autoload"] = "Reset autoload",
            ["manager.save.autoload_none"] = "Autoload config: none",
            ["manager.save.autoload_value"] = "Autoload config: {name}",
            ["manager.theme.settings"] = "Theme settings",
            ["manager.theme.background"] = "Background color",
            ["manager.theme.main"] = "Main color",
            ["manager.theme.surface"] = "Surface color",
            ["manager.theme.surface_alt"] = "Surface alt color",
            ["manager.theme.accent"] = "Accent color",
            ["manager.theme.outline"] = "Outline color",
            ["manager.theme.font_color"] = "Font color",
            ["manager.theme.muted_font"] = "Muted font color",
            ["manager.theme.success"] = "Success color",
            ["manager.theme.warning"] = "Warning color",
            ["manager.theme.info"] = "Info color",
            ["manager.theme.destructive"] = "Destructive color",
            ["manager.theme.font"] = "Font",
            ["manager.theme.list"] = "Theme list",
            ["manager.theme.set_default"] = "Set as default",
            ["manager.theme.custom_name"] = "Custom theme name",
            ["manager.theme.create"] = "Create theme",
            ["manager.theme.load"] = "Load theme",
            ["manager.theme.overwrite"] = "Overwrite theme",
            ["manager.theme.delete"] = "Delete theme",
            ["manager.theme.refresh"] = "Refresh list",
            ["manager.theme.reset_default"] = "Reset default",
        },
        vi = {
            ["locale.language"] = "Ngôn ngữ",
            ["locale.english"] = "Tiếng Anh",
            ["locale.japanese"] = "Tiếng Nhật",
            ["manager.interface.appearance"] = "Giao diện",
            ["manager.interface.utility"] = "Tiện ích",
            ["manager.interface.server"] = "Máy chủ",
            ["manager.interface.auto_minimize"] = "Tự động thu nhỏ",
            ["manager.interface.auto_execute"] = "Tự động thực thi",
            ["manager.interface.anti_afk"] = "Chống AFK",
            ["manager.interface.performance"] = "Chế độ hiệu năng cao",
            ["manager.interface.fps_cap"] = "Giới hạn FPS",
            ["manager.interface.auto_rejoin"] = "Tự động vào lại",
            ["manager.interface.low_player_hop"] = "Chuyển máy chủ ít người",
            ["manager.interface.staff_detector"] = "Phát hiện nhân viên",
            ["manager.interface.server_hop"] = "Chuyển máy chủ",
            ["manager.save.configuration"] = "Cấu hình",
            ["manager.save.config_name"] = "Tên cấu hình",
            ["manager.save.create"] = "Tạo cấu hình",
            ["manager.save.config_list"] = "Danh sách cấu hình",
            ["manager.save.load"] = "Tải cấu hình",
            ["manager.save.delete"] = "Xóa cấu hình",
            ["manager.save.refresh"] = "Làm mới danh sách",
            ["manager.theme.settings"] = "Cài đặt giao diện",
            ["manager.theme.list"] = "Danh sách giao diện",
            ["manager.theme.create"] = "Tạo giao diện",
            ["manager.theme.load"] = "Tải giao diện",
            ["manager.theme.delete"] = "Xóa giao diện",
        },
        id = {
            ["locale.language"] = "Bahasa",
            ["locale.english"] = "Inggris",
            ["locale.japanese"] = "Jepang",
            ["manager.interface.appearance"] = "Antarmuka",
            ["manager.interface.utility"] = "Utilitas",
            ["manager.interface.server"] = "Server",
            ["manager.interface.auto_minimize"] = "Minimalkan otomatis",
            ["manager.interface.auto_execute"] = "Jalankan otomatis",
            ["manager.interface.anti_afk"] = "Anti AFK",
            ["manager.interface.performance"] = "Mode performa tinggi",
            ["manager.interface.fps_cap"] = "Batas FPS",
            ["manager.interface.auto_rejoin"] = "Gabung ulang otomatis",
            ["manager.interface.low_player_hop"] = "Pindah ke server sepi",
            ["manager.interface.staff_detector"] = "Deteksi staf",
            ["manager.interface.server_hop"] = "Pindah server",
            ["manager.save.configuration"] = "Konfigurasi",
            ["manager.save.config_name"] = "Nama konfigurasi",
            ["manager.save.create"] = "Buat konfigurasi",
            ["manager.save.config_list"] = "Daftar konfigurasi",
            ["manager.save.load"] = "Muat konfigurasi",
            ["manager.save.delete"] = "Hapus konfigurasi",
            ["manager.save.refresh"] = "Segarkan daftar",
            ["manager.theme.settings"] = "Pengaturan tema",
            ["manager.theme.list"] = "Daftar tema",
            ["manager.theme.create"] = "Buat tema",
            ["manager.theme.load"] = "Muat tema",
            ["manager.theme.delete"] = "Hapus tema",
        },
        ["pt-BR"] = {
            ["locale.language"] = "Idioma",
            ["locale.english"] = "Inglês",
            ["locale.japanese"] = "Japonês",
            ["manager.interface.appearance"] = "Interface",
            ["manager.interface.utility"] = "Utilitários",
            ["manager.interface.server"] = "Servidor",
            ["manager.interface.auto_minimize"] = "Minimizar automaticamente",
            ["manager.interface.auto_execute"] = "Executar automaticamente",
            ["manager.interface.anti_afk"] = "Anti-AFK",
            ["manager.interface.performance"] = "Modo de alto desempenho",
            ["manager.interface.fps_cap"] = "Limite de FPS",
            ["manager.interface.auto_rejoin"] = "Reconectar automaticamente",
            ["manager.interface.low_player_hop"] = "Trocar para servidor vazio",
            ["manager.interface.staff_detector"] = "Detectar moderadores",
            ["manager.interface.server_hop"] = "Trocar de servidor",
            ["manager.save.configuration"] = "Configuração",
            ["manager.save.config_name"] = "Nome da configuração",
            ["manager.save.create"] = "Criar configuração",
            ["manager.save.config_list"] = "Lista de configurações",
            ["manager.save.load"] = "Carregar configuração",
            ["manager.save.delete"] = "Excluir configuração",
            ["manager.save.refresh"] = "Atualizar lista",
            ["manager.theme.settings"] = "Configurações de tema",
            ["manager.theme.list"] = "Lista de temas",
            ["manager.theme.create"] = "Criar tema",
            ["manager.theme.load"] = "Carregar tema",
            ["manager.theme.delete"] = "Excluir tema",
        },
        ["es-419"] = {
            ["locale.language"] = "Idioma",
            ["locale.english"] = "Inglés",
            ["locale.japanese"] = "Japonés",
            ["manager.interface.appearance"] = "Interfaz",
            ["manager.interface.utility"] = "Utilidades",
            ["manager.interface.server"] = "Servidor",
            ["manager.interface.auto_minimize"] = "Minimizar automáticamente",
            ["manager.interface.auto_execute"] = "Ejecutar automáticamente",
            ["manager.interface.anti_afk"] = "Anti-AFK",
            ["manager.interface.performance"] = "Modo de alto rendimiento",
            ["manager.interface.fps_cap"] = "Límite de FPS",
            ["manager.interface.auto_rejoin"] = "Reconectar automáticamente",
            ["manager.interface.low_player_hop"] = "Cambiar a servidor vacío",
            ["manager.interface.staff_detector"] = "Detectar moderadores",
            ["manager.interface.server_hop"] = "Cambiar de servidor",
            ["manager.save.configuration"] = "Configuración",
            ["manager.save.config_name"] = "Nombre de configuración",
            ["manager.save.create"] = "Crear configuración",
            ["manager.save.config_list"] = "Lista de configuraciones",
            ["manager.save.load"] = "Cargar configuración",
            ["manager.save.delete"] = "Eliminar configuración",
            ["manager.save.refresh"] = "Actualizar lista",
            ["manager.theme.settings"] = "Configuración del tema",
            ["manager.theme.list"] = "Lista de temas",
            ["manager.theme.create"] = "Crear tema",
            ["manager.theme.load"] = "Cargar tema",
            ["manager.theme.delete"] = "Eliminar tema",
        },
        ko = {
            ["locale.language"] = "언어",
            ["locale.english"] = "영어",
            ["locale.japanese"] = "일본어",
            ["manager.interface.appearance"] = "인터페이스",
            ["manager.interface.utility"] = "유틸리티",
            ["manager.interface.server"] = "서버",
            ["manager.interface.auto_minimize"] = "자동 최소화",
            ["manager.interface.auto_execute"] = "자동 실행",
            ["manager.interface.anti_afk"] = "AFK 방지",
            ["manager.interface.performance"] = "고성능 모드",
            ["manager.interface.fps_cap"] = "FPS 제한",
            ["manager.interface.auto_rejoin"] = "자동 재접속",
            ["manager.interface.low_player_hop"] = "적은 인원 서버로 이동",
            ["manager.interface.staff_detector"] = "스태프 감지",
            ["manager.interface.server_hop"] = "서버 이동",
            ["manager.save.configuration"] = "구성",
            ["manager.save.config_name"] = "구성 이름",
            ["manager.save.create"] = "구성 만들기",
            ["manager.save.config_list"] = "구성 목록",
            ["manager.save.load"] = "구성 불러오기",
            ["manager.save.delete"] = "구성 삭제",
            ["manager.save.refresh"] = "목록 새로고침",
            ["manager.theme.settings"] = "테마 설정",
            ["manager.theme.list"] = "테마 목록",
            ["manager.theme.create"] = "테마 만들기",
            ["manager.theme.load"] = "테마 불러오기",
            ["manager.theme.delete"] = "테마 삭제",
        },
        ["zh-CN"] = {
            ["locale.language"] = "语言",
            ["locale.english"] = "英语",
            ["locale.japanese"] = "日语",
            ["manager.interface.appearance"] = "界面",
            ["manager.interface.utility"] = "实用工具",
            ["manager.interface.server"] = "服务器",
            ["manager.interface.auto_minimize"] = "自动最小化",
            ["manager.interface.auto_execute"] = "自动执行",
            ["manager.interface.anti_afk"] = "防挂机",
            ["manager.interface.performance"] = "高性能模式",
            ["manager.interface.fps_cap"] = "FPS 上限",
            ["manager.interface.auto_rejoin"] = "自动重新加入",
            ["manager.interface.low_player_hop"] = "切换到低人数服务器",
            ["manager.interface.staff_detector"] = "管理员检测",
            ["manager.interface.server_hop"] = "切换服务器",
            ["manager.save.configuration"] = "配置",
            ["manager.save.config_name"] = "配置名称",
            ["manager.save.create"] = "创建配置",
            ["manager.save.config_list"] = "配置列表",
            ["manager.save.load"] = "加载配置",
            ["manager.save.delete"] = "删除配置",
            ["manager.save.refresh"] = "刷新列表",
            ["manager.theme.settings"] = "主题设置",
            ["manager.theme.list"] = "主题列表",
            ["manager.theme.create"] = "创建主题",
            ["manager.theme.load"] = "加载主题",
            ["manager.theme.delete"] = "删除主题",
        },
        ja = {
            ["locale.language"] = "言語",
            ["locale.english"] = "英語",
            ["locale.japanese"] = "日本語",
            ["manager.interface.appearance"] = "インターフェース",
            ["manager.interface.utility"] = "ユーティリティ",
            ["manager.interface.server"] = "サーバー",
            ["manager.interface.auto_minimize"] = "自動最小化",
            ["manager.interface.auto_execute"] = "自動実行",
            ["manager.interface.anti_afk"] = "AFK 防止",
            ["manager.interface.performance"] = "超軽量モード",
            ["manager.interface.fps_cap"] = "FPS 上限",
            ["manager.interface.auto_rejoin"] = "自動再参加",
            ["manager.interface.low_player_hop"] = "少人数サーバーへ移動",
            ["manager.interface.anti_stuck_hop"] = "停滞時サーバー移動",
            ["manager.interface.anti_stuck_seconds"] = "停滞判定秒数",
            ["manager.interface.anti_stuck_disabled"] = "停滞時サーバー移動: 無効",
            ["manager.interface.anti_stuck_disabled_delay"] = "停滞時サーバー移動: 無効 (待機: {time})",
            ["manager.interface.anti_stuck_remaining"] = "停滞時サーバー移動: 残り {time}",
            ["manager.interface.staff_detector"] = "スタッフ検出",
            ["manager.interface.webhook_url"] = "Discord Webhook URL",
            ["manager.interface.server_hop"] = "サーバー移動",
            ["manager.save.configuration"] = "設定",
            ["manager.save.config_name"] = "設定名",
            ["manager.save.create"] = "設定を作成",
            ["manager.save.config_list"] = "設定一覧",
            ["manager.save.load"] = "設定を読込",
            ["manager.save.overwrite"] = "設定を上書き",
            ["manager.save.delete"] = "設定を削除",
            ["manager.save.refresh"] = "一覧を更新",
            ["manager.save.set_autoload"] = "自動読込に設定",
            ["manager.save.reset_autoload"] = "自動読込を解除",
            ["manager.save.autoload_none"] = "自動読込設定: なし",
            ["manager.save.autoload_value"] = "自動読込設定: {name}",
            ["manager.theme.settings"] = "テーマ設定",
            ["manager.theme.background"] = "背景色",
            ["manager.theme.main"] = "メイン色",
            ["manager.theme.surface"] = "サーフェス色",
            ["manager.theme.surface_alt"] = "代替サーフェス色",
            ["manager.theme.accent"] = "アクセント色",
            ["manager.theme.outline"] = "輪郭色",
            ["manager.theme.font_color"] = "文字色",
            ["manager.theme.muted_font"] = "控えめな文字色",
            ["manager.theme.success"] = "成功色",
            ["manager.theme.warning"] = "警告色",
            ["manager.theme.info"] = "情報色",
            ["manager.theme.destructive"] = "危険色",
            ["manager.theme.font"] = "フォント",
            ["manager.theme.list"] = "テーマ一覧",
            ["manager.theme.set_default"] = "既定に設定",
            ["manager.theme.custom_name"] = "カスタムテーマ名",
            ["manager.theme.create"] = "テーマを作成",
            ["manager.theme.load"] = "テーマを読込",
            ["manager.theme.overwrite"] = "テーマを上書き",
            ["manager.theme.delete"] = "テーマを削除",
            ["manager.theme.refresh"] = "一覧を更新",
            ["manager.theme.reset_default"] = "既定を解除",
        },
    },
    ChangedCallbacks = {},
}

local function normalizeLocale(locale)
    return tostring(locale or "en"):gsub("_", "-")
end

local function getLanguage(locale)
    return normalizeLocale(locale):match("^([^-]+)") or "en"
end

local function getDictionary(dictionaries, locale)
    locale = normalizeLocale(locale)
    if dictionaries[locale] then
        return dictionaries[locale]
    end

    local lowerLocale = locale:lower()
    for dictionaryLocale, dictionary in dictionaries do
        if dictionaryLocale:lower() == lowerLocale then
            return dictionary
        end
    end

    return nil
end

local function applyParams(value, params)
    if typeof(params) ~= "table" then
        return value
    end

    return value:gsub("{([%w_]+)}", function(name)
        local replacement = params[name]
        return replacement == nil and ("{" .. name .. "}") or tostring(replacement)
    end)
end

function LocaleManager:SetLibrary(library)
    self.Library = library
    if library and typeof(library.SetLocaleManager) == "function" then
        library:SetLocaleManager(self)
    end
    return self
end

function LocaleManager:RegisterDictionary(locale, dictionary)
    assert(typeof(dictionary) == "table", "dictionary must be a table")
    locale = normalizeLocale(locale)
    self.Dictionaries[locale] = self.Dictionaries[locale] or {}
    for key, value in dictionary do
        if typeof(key) == "string" and typeof(value) == "string" then
            self.Dictionaries[locale][key] = value
        end
    end
    return self
end

function LocaleManager:RegisterDictionaries(dictionaries)
    assert(typeof(dictionaries) == "table", "dictionaries must be a table")
    for locale, dictionary in dictionaries do
        self:RegisterDictionary(locale, dictionary)
    end
    return self
end

function LocaleManager:T(key, params)
    assert(typeof(key) == "string", "translation key must be a string")
    local locale = normalizeLocale(self.Locale)
    local language = getLanguage(locale)
    local exact = getDictionary(self.Dictionaries, locale)
    local base = getDictionary(self.Dictionaries, language)
    local english = self.Dictionaries.en or {}
    local value = (exact and exact[key]) or (base and base[key]) or english[key] or key
    return applyParams(value, params)
end

function LocaleManager:SetLocale(locale)
    self.Locale = normalizeLocale(locale)
    self:RefreshAll()
    for _, callback in self.ChangedCallbacks do
        task.spawn(callback, self.Locale)
    end
    return self.Locale
end

function LocaleManager:DetectLocale()
    local locale = "en"
    pcall(function()
        locale = LocalizationService.RobloxLocaleId
            or (Players.LocalPlayer and Players.LocalPlayer.LocaleId)
            or "en"
    end)
    return normalizeLocale(locale)
end

function LocaleManager:OnChanged(callback)
    assert(typeof(callback) == "function", "callback must be a function")
    table.insert(self.ChangedCallbacks, callback)
    return callback
end

function LocaleManager:RefreshAll()
    if self.Library and typeof(self.Library.RefreshAllLocaleObjects) == "function" then
        self.Library:RefreshAllLocaleObjects()
    end
end

function LocaleManager:GetSupportedLocales()
    local locales = {}
    for locale in self.Dictionaries do
        table.insert(locales, locale)
    end
    table.sort(locales)
    return locales
end

return LocaleManager
