script_name("AutoFila Horizonte com Auto-Update")
script_author("LD")
script_version(9) -- Incremente este numero no script e no JSON a cada nova atualizacao

local sampev = require 'lib.samp.events'
local async_http = require 'async-http'

local ativo = true
local emAtendimento = false

-- LINKS DO SEU GITHUB (Substitua com os seus links raw do GitHub)
local URL_VERSAO = "https://raw.githubusercontent.com/vladsonos49-dotcom/autofila/main/version.json"

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FF00}[AutoFila]{FFFFFF} Mod Carregado (v9)! Verificando atualizacoes...", -1)
    
    -- Checa por atualizacoes ao iniciar
    verificarAtualizacao()

    -- Comando para Ligar/Desligar
    sampRegisterChatCommand("autofila", function()
        ativo = not ativo
        local status = ativo and "{00FF00}ATIVADO" or "{FF0000}DESATIVADO"
        sampAddChatMessage("[AutoFila] Status: " .. status, -1)
    end)

    -- Comando para forcar atualizacao manual
    sampRegisterChatCommand("attfila", function()
        verificarAtualizacao(true)
    end)

    wait(-1)
end

--------------------------------------------------------------------------------
-- SISTEMA DE ATUALIZAÇÃO AUTOMÁTICA
--------------------------------------------------------------------------------

function verificarAtualizacao(manual)
    async_http.request(URL_VERSAO, 'GET', function(response)
        if response and response.status_code == 200 then
            local ok, data = pcall(decodeJson, response.text)
            if ok and data and data.version then
                if data.version > thisScript().version then
                    sampAddChatMessage("{FFFF00}[AutoFila] Nova versao encontrada! Baixando atualizacao...", -1)
                    baixarNovoScript(data.url)
                else
                    if manual then
                        sampAddChatMessage("{00FF00}[AutoFila] Seu script ja esta na versao mais recente!", -1)
                    end
                end
            end
        end
    end)
end

function baixarNovoScript(urlScript)
    async_http.request(urlScript, 'GET', function(response)
        if response and response.status_code == 200 then
            local file = io.open(thisScript().path, "wb")
            if file then
                file:write(response.text)
                file:close()
                sampAddChatMessage("{00FF00}[AutoFila] Script atualizado com sucesso! Recarregando...", -1)
                thisScript():reload()
            end
        else
            sampAddChatMessage("{FF0000}[AutoFila] Falha ao baixar a nova versao.", -1)
        end
    end)
end

--------------------------------------------------------------------------------
-- COMANDOS DIGITADOS
--------------------------------------------------------------------------------

function sampev.onSendChat(message)
    local cmd = message:lower()

    if cmd == "/fila" or cmd == "/fa" or cmd:find("^/finalizaratendimento") or cmd:find("^/fa ") then
        emAtendimento = false
    end
end

--------------------------------------------------------------------------------
-- EVENTOS DO SERVIDOR
--------------------------------------------------------------------------------

function sampev.onServerMessage(color, text)
    if not ativo then return end

    local txt = text:lower()

    if txt:find("atendimento finalizado") or txt:find("voce finalizou") or txt:find("atendimento encerrado") then
        emAtendimento = false
    end

    if not emAtendimento then
        if txt:find("solicitou um atendimento") or txt:find("use /fila") or txt:find("fila para atende%-lo") then
            sampSendChat("/fila")
        end
    end
end

--------------------------------------------------------------------------------
-- DIÁLOGOS (CAIXA DA FILA)
--------------------------------------------------------------------------------

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if not ativo or emAtendimento then return end

    local t = title:lower()
    local body = text:lower()

    if t:find("fila") or t:find("atendimento") or body:find("tempo de espera") or body:find("novato") then
        if not body:find("nenhum") and body ~= "" then
            emAtendimento = true

            sampSendDialogResponse(dialogId, 1, 0, "")

            lua_thread.create(function()
                wait(350)
                sampSendChat("Ola, em que posso ajudar?")

                wait(15000)
                emAtendimento = false
            end)

            return false
        else
            emAtendimento = false
        end
    end
end
