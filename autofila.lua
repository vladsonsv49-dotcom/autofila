script_name("AutoFila Horizonte Universal")
script_author("LD")
script_version(1)

local sampev = require 'lib.samp.events'
local async_http = require 'async-http'

local ativo = true
local emAtendimento = false

-- Link do seu version.json no GitHub
local URL_VERSAO = "https://raw.githubusercontent.com/vladsonos49-dotcom/autofila/main/version.json"

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FF00}[AutoFila]{FFFFFF} Mod Carregado! Verificando atualizacoes...", -1)
    
    verificarAtualizacao()

    sampRegisterChatCommand("autofila", function()
        ativo = not ativo
        local status = ativo and "{00FF00}ATIVADO" or "{FF0000}DESATIVADO"
        sampAddChatMessage("[AutoFila] Status: " .. status, -1)
    end)

    sampRegisterChatCommand("attfila", function()
        verificarAtualizacao(true)
    end)

    wait(-1)
end

--------------------------------------------------------------------------------
-- SISTEMA DE ATUALIZAÇÃO (COMPATÍVEL COM MONETLOADER)
--------------------------------------------------------------------------------

function verificarAtualizacao(manual)
    async_http.request(URL_VERSAO, 'GET', function(response)
        if response and response.status_code == 200 then
            local ok, data = pcall(decodeJson, response.text)
            if ok and data and data.version then
                if data.version > thisScript().version then
                    sampAddChatMessage("{FFFF00}[AutoFila] Nova versao encontrada! Baixando...", -1)
                    baixarNovoScript(data.url)
                else
                    if manual then
                        sampAddChatMessage("{00FF00}[AutoFila] Seu script ja esta atualizado!", -1)
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
                sampAddChatMessage("{00FF00}[AutoFila] Atualizado com sucesso! Reinicie ou recarregue.", -1)
                pcall(function() thisScript():reload() end)
            end
        else
            sampAddChatMessage("{FF0000}[AutoFila] Falha ao baixar atualizacao.", -1)
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
-- CAIXA DE DIÁLOGO
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
