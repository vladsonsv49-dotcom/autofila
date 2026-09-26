script_name("AutoFila Horizonte Universal")
script_author("LD")
script_version(1)

local sampev = require 'lib.samp.events'

local ativo = true
local emAtendimento = false

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FF00}[AutoFila]{FFFFFF} Mod Carregado com Sucesso!", -1)

    sampRegisterChatCommand("autofila", function()
        ativo = not ativo
        local status = ativo and "{00FF00}ATIVADO" or "{FF0000}DESATIVADO"
        sampAddChatMessage("[AutoFila] Status: " .. status, -1)
    end)

    wait(-1)
end

--------------------------------------------------------------------------------
-- INTERCEPTAÇÃO DE COMANDOS DIGITADOS
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
