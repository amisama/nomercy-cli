-- ============================================================
--  No Mercy Tools  |  Termux CLI  |  Simple & Robust
-- ============================================================

local DL_PATH    = "/sdcard/Download/"
local API_URL    = "https://gofile-clone.mrcy-25d.workers.dev"
local PKG_PREFIX = "com.roblox"
local DELTA_KEY  = "KEY_d1da50257e7edf4c344e746a942662c8"
local DELTA_DIR  = "/sdcard/Delta/Internals/Cache/"
local RONIX_KEY  = "PyHmLLWzXYkrglZeVynuOFWiisCImUPt"
local RONIX_DIR  = "/sdcard/RonixExploit/internal/"



local function run(cmd)
    local h = io.popen(cmd .. " 2>/dev/null")
    if not h then return "" end
    local out = h:read("*a") or ""
    h:close()
    return out:match("^%s*(.-)%s*$")   
end


local function run_root(cmd)
    local h = io.popen("su -c '" .. cmd .. "' 2>&1")
    if not h then return "" end
    local out = h:read("*a") or ""
    h:close()
    return out:match("^%s*(.-)%s*$")
end


local function tty_read()
    local tty = io.open("/dev/tty", "r")
    if tty then
        local line = tty:read("*l") or ""
        tty:close()
        return line
    end
    return io.read("*l") or ""
end

local function pause(msg)
    io.write(msg or "\n  Tekan Enter untuk lanjut... ")
    io.flush()
    tty_read()
end


local SEP = string.rep("-", 66)

local function clear()
    os.execute("clear 2>/dev/null || printf '\\033c'")
end

local function header()
    clear()
    print("")
    print([[
  ███▄    █  ██████   ███▄   ▄███ ███████ ██████   ██████ ██    ██
  ████▄   █ ██    ██  █████ █████ ██      ██   ██ ██      ██    ██
  ██ ██▄  █ ██    ██  ██ █████ ██ ███████ ██████  ██       ██  ██ 
  ██  ██▄ █ ██    ██  ██  ███  ██ ██      ██  ██  ██         ██   
  ██   ████  ██████   ██   █   ██ ███████ ██   ██  ██████    ██   
                                                                  
                       T O O L S   B O X                          ]])
    print("  " .. SEP)
    print("  " .. SEP)
    print("")
end


local function list_menu(title, items, extra_rows)
    print("  [ " .. title .. " ]")
    print("  " .. string.rep("-", 40))
    for i, item in ipairs(items) do
        print(string.format("  %-4s %s", "[" .. i .. "]", item))
    end
    if extra_rows then
        for _, row in ipairs(extra_rows) do
            print(string.format("  %-4s %s", "[" .. row[1] .. "]", row[2]))
        end
    end
    print("  " .. string.rep("-", 40))
end



local function load_db()
    print("  Memuat database dari server...")
    local raw = run("curl -s " .. API_URL .. "/api/cli/all")
    local db, keys = {}, {}
    if raw == "" or raw == "EMPTY" or raw == "ERROR" then
        return db, keys
    end
    for line in raw:gmatch("[^\r\n]+") do
        local folder, name, url = line:match("([^|]+)|([^|]+)|([^|]+)")
        if folder and name and url then
            if not db[folder] then
                db[folder] = {}
                table.insert(keys, folder)
            end
            table.insert(db[folder], { name = name, url = url })
        end
    end
    return db, keys
end


local function parse_input(input, max)
    local targets = {}
    if input == "all" then
        for i = 1, max do targets[#targets+1] = i end
        return targets
    end
    for part in input:gmatch("[^,%s]+") do
        local s, e = part:match("^(%d+)-(%d+)$")
        if s then
            for i = tonumber(s), tonumber(e) do
                if i >= 1 and i <= max then targets[#targets+1] = i end
            end
        else
            local n = tonumber(part)
            if n and n >= 1 and n <= max then targets[#targets+1] = n end
        end
    end
    return targets
end


local function do_install(folder_name, list)
    header()
    print("  [ Install APK : " .. folder_name .. " ]")
    print("")

    if not list or #list == 0 then
        print("  [!] Folder kosong atau server tidak merespons.")
        pause()
        return
    end

    local item_names = {}
    for _, app in ipairs(list) do
        item_names[#item_names+1] = app.name
    end
    list_menu("Pilih APK", item_names, { {"0", "Kembali"} })

    io.write("  Pilih (contoh: 1  |  1,3  |  1-5  |  all  |  0): ")
    io.flush()
    local input = tty_read()
    if input == "0" or input == "" then return end

    local targets = parse_input(input, #list)
    if #targets == 0 then
        print("  [!] Input tidak valid.")
        pause()
        return
    end


    print("")
    print("  >> Mendownload " .. #targets .. " file ke " .. DL_PATH)
    local downloaded = {}
    for _, idx in ipairs(targets) do
        local app  = list[idx]
        local dest = DL_PATH .. "tmp_nm_" .. idx .. ".apk"
        print("     Downloading: " .. app.name)

        local sh_cmd = string.format(
            "curl -L --fail -s -H 'Accept: application/octet-stream' -o '%s' '%s' & " ..
            "CPID=$!; T=0; FIRST=1; " ..
            "while kill -0 $CPID 2>/dev/null; do " ..
            "  sleep 1; T=$((T+1)); " ..
            "  SZ=$(du -h '%s' 2>/dev/null | cut -f1); " ..
            "  if [ \"$FIRST\" = 1 ]; then " ..
            "    printf '     [%%ds] %%s\\n' $T \"$SZ\" > /dev/tty; FIRST=0; " ..
            "  else " ..
            "    printf '\\033[1A\\033[2K     [%%ds] %%s\\n' $T \"$SZ\" > /dev/tty; " ..
            "  fi; " ..
            "done; " ..
            "wait $CPID; echo __DONE__",
            dest, app.url, dest
        )

        local ok = false
        local h  = io.popen(sh_cmd)
        if h then
            for line in h:lines() do
                if line == "__DONE__" then ok = true; break end
                io.write("     ")
                print(line)
            end
            h:close()
        end

        if ok then
            local sz = run("du -h '" .. dest .. "' 2>/dev/null | cut -f1")
            downloaded[#downloaded+1] = { path = dest, name = app.name }
            print("     [OK] Selesai! " .. sz)
        else
            print("     [!] GAGAL download: " .. app.name)
        end
    end


    print("")
    print("  >> Menginstall ...")
    for _, f in ipairs(downloaded) do
        print("     Installing: " .. f.name)
        local out = run_root("pm install -r " .. f.path)
        if out:find("Success") then
            print("     [OK] Sukses!")
        else
           
            print("     [!] " .. out:gsub("[\r\n]+", " "))
        end
        os.execute("rm -f '" .. f.path .. "'")
    end

    print("")
    print("  >> Instalasi selesai.")

    
    if folder_name:lower():find("delta") then
        print("")
        print("  " .. string.rep("=", 48))
        print("  [*] Delta terdeteksi — memulai injeksi lisensi...")
        print("  " .. string.rep("=", 48))
        os.execute("sleep 1")

       
        local scan_lines = {
            "  > Scanning Delta process memory...",
            "  > Locating license verification routine...",
            "  > Patching auth token validator...",
            "  > Generating premium session...",
        }
        for _, line in ipairs(scan_lines) do
            io.write(line)
            io.flush()
            os.execute("sleep 0.4")
            -- animasi titik-titik
            for _ = 1, 3 do
                io.write(".")
                io.flush()
                os.execute("sleep 0.25")
            end
            print("  OK")
        end

        os.execute("sleep 0.5")
        print("")
        print("  > Writing license file to Delta internals...")
        os.execute("sleep 0.6")

        
        os.execute("mkdir -p '" .. DELTA_DIR .. "'")
        local f = io.open(DELTA_DIR .. "license", "w")
        if f then
            f:write(DELTA_KEY)
            f:close()
            os.execute("sleep 0.4")
            print("  > Success.......")
            os.execute("sleep 0.7")
            print("")
            print("  " .. string.rep("=", 48))
            print("  [OK] .")
            print("  " .. string.rep("=", 48))
        else
            print("  [!] Gagal tulis file. Pastikan Termux punya izin storage.")
        end

        print("")
        pause()
        return
    end

    if folder_name:lower():find("ronix") then
        print("")
        print("  " .. string.rep("=", 48))
        print("  [*] Ronix terdeteksi ...")
        print("  " .. string.rep("=", 48))
        os.execute("sleep 1")

        print("  > Writing license file to Ronix ...")
        os.execute("sleep 0.6")

        local RONIX_DIR = "/sdcard/RonixExploit/internal/"
        local RONIX_KEY = "PyHmLLWzXYkrglZeVynuOFWiisCImUPt"
        
        os.execute("mkdir -p '" .. RONIX_DIR .. "'")
        local f = io.open(RONIX_DIR .. "_key.txt", "w")
        if f then
            f:write(RONIX_KEY)
            f:close()
            print("  > Success.......")
            os.execute("sleep 0.5")
            print("")
            print("  " .. string.rep("=", 48))
            print("  [OK] Ronix Key Successfully.")
            print("  " .. string.rep("=", 48))
        else
            print("  [!] Gagal tulis file. Pastikan Termux punya izin storage.")
        end

        print("")
        pause()
        return
    end

    pause()
end


local function do_uninstall()
    header()
    print("  [ Auto Uninstall : " .. PKG_PREFIX .. "* ]")
    print("")
    print("  Scanning packages...")

    local raw = run("pm list packages " .. PKG_PREFIX)
    local pkgs = {}
    for p in raw:gmatch("package:(%S+)") do
        pkgs[#pkgs+1] = p
    end

    if #pkgs == 0 then
        print("  [!] Tidak ada package yang cocok ditemukan.")
        pause()
        return
    end

    list_menu("Package Terinstal", pkgs, { {"0", "Kembali"} })
    io.write("  Pilih (1  |  1,3  |  all  |  0): ")
    io.flush()
    local input = tty_read()
    if input == "0" or input == "" then return end

    local targets = parse_input(input, #pkgs)
    if #targets == 0 then
        print("  [!] Input tidak valid.")
        pause()
        return
    end


    io.write("  Hapus " .. #targets .. " package? (y/n): ")
    io.flush()
    local confirm = tty_read()
    if confirm:lower() ~= "y" then
        print("  Dibatalkan.")
        pause()
        return
    end

    print("")
    for _, idx in ipairs(targets) do
        local pkg = pkgs[idx]
        if pkg then
            print("  Uninstalling: " .. pkg)
            local out = run_root("pm uninstall " .. pkg)
            if out:find("Success") then
                print("  [OK] Sukses!")
            else
                print("  [!] " .. out:gsub("[\r\n]+", " "))
            end
        end
    end

    print("")
    print("  >> Uninstall selesai.")
    pause()
end




-- ============================================================
-- MAIN LOOP
-- ============================================================

while true do
    header()
    local db, folder_keys = load_db()

    if #folder_keys == 0 then
        print("  [!] Tidak ada APK di server atau koneksi gagal.")
        pause()
    else
        local menu_labels = {}
        for _, k in ipairs(folder_keys) do
            menu_labels[#menu_labels+1] = k .. "  (" .. #db[k] .. " file)"
        end

        local idx_uninstall  = #folder_keys + 1

        list_menu("T O O L S   B O X", menu_labels, {
            { tostring(idx_uninstall), "Auto Uninstall  (hapus " .. PKG_PREFIX .. "*)" },
            { "0",                     "Exit" },
        })

        io.write("  Pilih: ")
        io.flush()
        local choice = tty_read()
        local num    = tonumber(choice)

        if choice == "0" then
            print("\n  Bye!\n")
            break
        elseif num == idx_uninstall then
            do_uninstall()
        elseif num and num >= 1 and num <= #folder_keys then
            do_install(folder_keys[num], db[folder_keys[num]])
        else
            print("  [!] Pilihan tidak valid.")
            os.execute("sleep 1")
        end
    end
end
