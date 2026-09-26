script_name("AutoFila Horizonte V8")
script_author("Gemini")
script_version("8.0")

local sampev = require 'lib.samp.events'

local ativo = true
local emAtendimento = false

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FF00}[AutoFila]{FFFFFF} Script V8 Carregado! Use {FFFF00}/autofila{FFFFFF} para Ligar/Desligar.", -1)

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

    -- Libera o estado ao usar /fa ou /fila
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

    -- Reset se o atendimento for finalizado
    if txt:find("atendimento finalizado") or txt:find("voce finalizou") or txt:find("atendimento encerrado") then
        emAtendimento = false
    end

    -- 1. Captura a notificação de nova fila para abrir o menu /fila
    if not emAtendimento then
        if txt:find("solicitou um atendimento") or txt:find("use /fila") or txt:find("fila para atende%-lo") then
            sampSendChat("/fila")
        end
    end
end

--------------------------------------------------------------------------------
-- CAIXA DE DIÁLOGO DA FILA (SOMENTE VOCÊ PEGA)
--------------------------------------------------------------------------------

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if not ativo or emAtendimento then return end

    local t = title:lower()
    local body = text:lower()

    -- Confirma se a caixa é a Fila de Atendimento
    if t:find("fila") or t:find("atendimento") or body:find("tempo de espera") or body:find("novato") then
        if not body:find("nenhum") and body ~= "" then
            -- MARCA QUE VOCÊ ATENDEU
            emAtendimento = true

            -- Envia a confirmação para pegar o atendimento na caixa
            sampSendDialogResponse(dialogId, 1, 0, "")

            -- Envia a saudação APENAS porque FOI VOCÊ quem clicou/pegou a fila
            lua_thread.create(function()
                wait(350)
                sampSendChat("Ola, em que posso ajudar?")

                -- Trava de segurança: libera o mod após 15s para a próxima fila
                wait(15000)
                emAtendimento = false
            end)

            return false -- Oculta o menu da tela
        else
            emAtendimento = false
        end
    end
end
