# OXLYN Advanced Garage System — Exports v1.1.1

API comum às edições normal e open-source, para apps Garage/Valet/Parking do CodeM mPhone 2.5, LB-Phone e outros recursos FiveM.

## Instalação

Use apenas **uma** edição e dê à pasta do recurso o nome `oxlyn-garage`. Inicie `oxmysql`, o framework e a garagem antes do telefone. Se mudar o nome, substitua `oxlyn-garage` nos exemplos/adaptadores. Os exports de servidor que consultam SQL devem correr num callback/evento/thread que permita `await`.

- CodeM mPhone 2.5: [instalação do adaptador Valet](install/CODEM_PHONE.md), `install/codem_phone_server.lua` e `install/codem_phone_client.lua`.
- LB-Phone: [instalação do adaptador Garage](install/LB_PHONE.md), `install/lb_phone_server.lua` e `install/lb_phone_client.lua`.
- Outros telefones: usar os exports abaixo no backend/cliente da app. Não é necessário um export do próprio telefone para consultar a garagem.

Os ficheiros de `install/` são para integrar **no telefone** conforme os respetivos guias; não os adicione aos scripts da garagem. Os telefones são opcionais e não são dependências do recurso. Os adaptadores foram validados com testes simulados; deve ser feito um teste no servidor com a versão do telefone instalada.

## Garagens locais (v1.0.3)

Ative **/garageeditor → garagem → Identidade → Apenas veículos desta garagem** e guarde. O documento da garagem usa `localVehiclesOnly = true`; por defeito é `false` para manter as regras existentes.

Veículos atribuídos a uma garagem local não podem ser retirados, transferidos ou recuperados remotamente noutra garagem; a garagem local também não pode importar veículos atribuídos a outro local. A recolha/recuperação dos seus veículos exige estar junto ao ponto de interação ou a um lugar de estacionamento configurado, incluindo a pré-visualização. Conduzir e guardar fisicamente noutra garagem continua permitido. Viaturas novas/importadas sem garagem normal válida mantêm um percurso de recuperação; apreensões e frotas conservam os seus fluxos próprios.

`GetPhoneVehicles` continua a permitir consultar/localizar os carros, mas devolve `canValet = false` quando estão atribuídos a uma garagem local. `PreparePhoneVehicle`, `RequestValet` e transferências remotas recusam estes pedidos com `garage_local_only`, antes de cobrar ou alterar o estado. Os adaptadores CodeM/LB usam estas mesmas validações. Os exports administrativos de confiança, como `SetVehicleGarage`, continuam a permitir uma reatribuição explícita.

Não altere o ID de uma garagem com veículos associados só para a renomear; altere o nome visível. A mudança de ID mantém o comportamento existente de apagar/recriar a garagem.

## Veículos perdidos (v1.0.4)

`Config.Garage.lostVehicles.mode` escolhe `garage` (recuperação atual), `impound` (apreensão com multa/motivo fixos) ou `disabled` (sem recuperação). Em `impound`, `autoImpound=true` deteta automaticamente veículos marcados como fora que desapareceram do mundo do servidor, após `graceSeconds`, verificados a cada `checkInterval` segundos. `impound.fee`, `impound.reason` e `impound.lot` definem multa, motivo e parque; a multa só é paga na libertação.

Veículos vivos, `/park`, reservas de spawn e contratos não são apreendidos por esta regra. Falta de streaming no cliente não significa perda. O estado recuperado é o último snapshot guardado. `restoreOnRestart` só se aplica ao modo `garage`; os outros modos mantêm a sua regra após reiniciar.

Os phones refletem o novo estado de apreensão através dos exports existentes e do evento `server:vehicleImpounded`; não é necessário instalar outro adaptador. Os exports administrativos de confiança conservam o seu funcionamento.

## Exports de cliente para apps

Os três primeiros exports aguardam uma resposta. Chame-os dentro de `CreateThread`, eventos ou callbacks NUI, nunca por frame. O proprietário é sempre o jogador que fez o pedido.

| Export | Resultado |
| --- | --- |
| `GetPhoneVehicles()` | `{ok=true, vehicles={...}}`, ou `{ok=false,error=...}` |
| `LocateVehicle(plate, waypoint?)` | Localização; coloca GPS por defeito. Passe `false` para apenas consultar. |
| `RequestValet(plate)` | `{ok=true,plate,key}` após criar o veículo, ou erro. Entrega num ponto de estrada livre próximo, sem NPC. |
| `ApplyPhoneVehicle(entity, data, options?)` | `boolean`; restaura propriedades e danos e inicia a confirmação do spawn/atribuição de chaves. `{deferConfirm=true}` permite ao servidor do telefone confirmar explicitamente via `ConfirmPhoneVehicle`. |
| `WaitForVehicleKeys(entity, timeoutMs?)` | Aguarda a atribuição confirmada por até 12 s (máximo 15 s). Devolve boolean e avisa quando falha. Chamar depois de confirmar o spawn. |
| `GetVehicleProperties(entity)` | Snapshot de propriedades/condição, ou `nil`. |
| `SetVehicleProperties(entity, props)` | `boolean`; aplica um snapshot à entidade. **Não grava SQL**. |

```lua
-- Dentro do cliente do telefone / recurso da app:
CreateThread(function()
    local response = exports['oxlyn-garage']:GetPhoneVehicles()
    if not response.ok then return end
    for _, vehicle in ipairs(response.vehicles) do
        print(vehicle.plate, vehicle.label, vehicle.state, vehicle.canValet)
    end
end)

-- Handlers dos botões da app (plate selecionada pelo utilizador):
local location = exports['oxlyn-garage']:LocateVehicle(plate, true)
local delivery = exports['oxlyn-garage']:RequestValet(plate)
```

`RequestValet` usa `Config.Phone.valet.fee/account`. Não cobre novamente no telefone ao usar este percurso. Se a app já tem o seu próprio NPC/spawn, use o fluxo de reserva seguinte.

## Exports de servidor para Garage / Valet

Estes exports são para recursos de servidor de confiança. Nunca aceite `source` ou `identifier` enviados pelo cliente: use o `source` real do callback do telefone.

| Export | Resultado / comportamento |
| --- | --- |
| `GetPhoneVehicles(source, format?)` | Array de veículos do jogador; `format='lb'` para LB ou `'codem'` para CodeM. Sem argumentos de proprietário enviados pelo cliente. |
| `LocateVehicle(source, plate)` | `{ok,kind,x,y,z,label,place?,live?,seenAt?,now}`; `kind`: `garage`, `impound`, `parked`, `world`, `lost`. `lost` não tem coordenadas. |
| `TransferVehicleToGarage(source, plate, garageId, account?)` | `{ok,message?,balances?}`. Move um veículo guardado, verifica acesso e cobra `Config.Garage.transferFee`; **não entrega um veículo na rua**. |
| `PreparePhoneVehicle(source, plate, coords?, heading?, options?)` | Reserva e marca o veículo como fora; devolve payload para o telefone criar uma única entidade. Não cria uma entidade por si só. |
| `ConfirmPhoneVehicle(source, plate, netId)` | `true` quando a confirmação é aceite para processamento ou já foi confirmada. A validação da entidade pode aguardar replicação. |
| `CancelPhoneVehicle(source, plate)` | `true` quando cancela uma reserva desse jogador sem entidade existente e repõe o estado; `false` se já confirmou, não existe reserva ou uma entidade já existe. |

### Formato da lista

```lua
{
    plate = 'ABC 123', key = 'ABC123', model = 123456789,
    modelName = 'sultan', label = 'Sultan',
    state = 'stored', -- stored | out | impounded
    garage = 'pillbox', garageLabel = 'Pillbox', location = 'Pillbox',
    type = 'car', -- car | bike | boat | plane
    impounded = false, parked = false, canValet = true,
    statistics = { engine = 48, body = 63, fuel = 21 }, -- 0–100 para o UI
    impoundReason = nil,
}
```

Alguns campos são opcionais para veículos antigos. CodeM inclui também `spawncode`, `inGarage` e `mods` (JSON). Os percentuais apresentados não substituem os valores exatos guardados em `props`. A lista não garante que uma entidade criada por outro recurso não esteja no mundo: o pedido de valet verifica novamente a existência antes de autorizar.

### Fluxo de reserva para um telefone com spawn/NPC próprios

```lua
-- SERVIDOR: source vem do callback autenticado da app.
local result = exports['oxlyn-garage']:PreparePhoneVehicle(
    source, plate,
    { x = spawn.x, y = spawn.y, z = spawn.z }, heading,
    { charge = false } -- apenas se o telefone já trata a taxa e o reembolso
)
if not result.ok then return result end
-- Envie result para o cliente destinatário / crie a entidade via OneSync.
-- Em falha, elimine qualquer entidade criada e cancele a reserva:
-- exports['oxlyn-garage']:CancelPhoneVehicle(source, plate)

-- CLIENTE: depois de a entidade existir e ter controlo de rede:
local applied = exports['oxlyn-garage']:ApplyPhoneVehicle(vehicle, result)
-- Depois da confirmação, espere pelas chaves antes de ligar o motor:
local keysReady = applied and exports['oxlyn-garage']:WaitForVehicleKeys(vehicle, 12000)
if applied then
    -- Ligar após colocar o condutor. Nunca deixar disableAutoStart=true
    -- num veículo entregue; uma chave atrasada deve poder usá-lo depois.
    SetVehicleEngineOn(vehicle, keysReady == true, true, false)
end
-- Se keysReady=false após confirmação, deixe a entidade fora, sem motor;
-- não cancele/reembolse uma entrega que já criou um veículo válido.
-- Se applied=false, termine a entrega, elimine a entidade e avise o
-- servidor do telefone para cancelar. Não prossiga com uma entidade sem mods.
```

Payload aprovado: `{ok=true, oxlyn=true, plate, key, model, props, spot={x,y,z,w}, spotIndex, label, garageLabel, engineOn, putIn=false}`. Para CodeM, o adaptador converte as propriedades para o JSON esperado pela app.

- `coords` deve ser uma tabela de números finitos dentro de `Config.Phone.valet.maxDistance` do jogador, por defeito 250 m. O servidor rejeita locais ocupados.
- Um adaptador **de servidor** pode omitir `coords` quando o telefone escolhe o local mais tarde. A confirmação continua limitada à distância configurada do ponto do jogador no momento do pedido e ao mesmo routing bucket.
- `options.charge` é `true` por defeito. `false` só é disponibilizado pelo export de servidor, nunca pelo callback de rede. Taxas cobradas pelo telefone devem ser devolvidas pelo próprio telefone se a entrega falhar.
- Confirme logo após criar/aplicar as propriedades, **antes** do percurso do NPC. A reserva expira em 30 segundos. Não crie novas entidades depois de cancelar ou expirar uma reserva.
- Uma matrícula já no mundo não volta ao estado guardado por timeout/cancelamento: fica fora para evitar duplicação e pode ser localizada/recuperada.
- Só aceita veículos pessoais guardados, com acesso à garagem de origem. Recusa apreendidos, estacionados com `/park`, contratos pendentes, reservas duplicadas, barcos/aviões e veículos de terceiros.
- Não utilize `SetVehicleGarage` para contornar a apreensão ou implementar valet.

Erros principais: `not_loaded`, `no_access`, `vehicle_not_owned`, `vehicle_out`, `vehicle_impounded`, `contract_locked`, `vehicle_wrong_type`, `garage_not_found`, `spot_occupied`, `not_enough_money`, `store_failed`; cliente pode devolver `busy`, `timeout` ou `spawn_failed`. Trate sempre `ok ~= true` como falha.

## Exports existentes

### Cliente

| Export | Função |
| --- | --- |
| `OpenGarage(id)` | Abre o menu dessa garagem; o servidor valida o acesso. |
| `OpenNearestGarage()` | Abre a garagem mais próxima segundo o percurso normal do cliente. |
| `OpenEditor()` | Abre o editor; permissões continuam a ser verificadas. |
| `IsOpen()` | `boolean`: existe UI da garagem com foco. |
| `GetGarages()` | Lista sincronizada de garagens e acesso do jogador. |
| `GetNearestGarage()` | Garagem próxima e distância, conforme a função de proximidade do cliente. |

Feche/liberte o foco do telefone antes de abrir o menu da garagem para evitar conflito entre NUIs.

### Servidor

| Export | Resultado / função |
| --- | --- |
| `GetGarages()` / `GetGarage(id)` | Array ordenado / documento ou `nil`. |
| `CanAccessGarage(source,id)` / `IsAdmin(source)` | `boolean`. |
| `SaveGarage(doc,by?)` | `success, garageOrError`. |
| `DeleteGarage(id)` | `boolean`. |
| `GetSettings()` / `SaveSettings(doc,by?)` | Configuração global / gravação normalizada. |
| `GetVehicle(plate)` | Registo normalizado ou `nil`; **não verifica o proprietário**. |
| `GetOwnedVehicles(identifier)` | Array por identifier ESX / citizenid QB/Qbox. Não é o source. |
| `SetVehicleGarage(plate,garageId)` | Utilitário administrativo: recusa reserva, contrato, `/park` e entidade existente. Não cobra taxas nem verifica permissões do jogador. |
| `ImpoundVehicle(plate,opts?)` | `success, reasonKey, vehicle?`; opções `lot,fee,reason,by,byName,entity,coords`. |
| `IsVehicleOut(plate)` | Se consta do registo de veículos fora deste recurso; não equivale a uma consulta global de todas as entidades. |
| `IsVehicleParked(plate)` | Se está no `/park` persistente. |
| `GetParkedVehicles()` | Array `{plate,key,owner,x,y,z,w,at}`; servidor de confiança. |

Não exponha exports administrativos diretamente num evento de rede. As funções de leitura administrativa podem devolver tabelas do recurso; trate-as como apenas leitura.

## Eventos de integração (escutar, não simular)

O prefixo é o nome real do recurso. Exemplos usando `oxlyn-garage`:

| Lado | Evento | Argumentos |
| --- | --- | --- |
| servidor | `oxlyn-garage:server:vehicleStored` | `source, plateKey, garageId` |
| servidor | `oxlyn-garage:server:vehicleOut` | `source, plateKey, netId, garageId` |
| servidor | `oxlyn-garage:server:vehicleImpounded` | `plateKey, lotId, fee, reason, by` |
| servidor | `oxlyn-garage:server:vehicleTransferred` | `plateKey, newIdentifier, newSource` |
| servidor | `oxlyn-garage:server:vehicleParked` / `vehicleUnparked` | `plateKey, source` |
| servidor | `oxlyn-garage:server:garageSaved` / `garageDeleted` | `garage` / `garageId` |
| cliente | `oxlyn-garage:client:vehicleStored` | `plateKey, garageId` |
| cliente | `oxlyn-garage:client:vehicleOut` | `plateKey, entityHandle` no spawn normal/OXLYN |

Use `AddEventHandler` para atualizar a app depois de uma alteração, sem consultas por frame. `ApplyPhoneVehicle` confirma o estado através do evento de servidor; a app do telefone pode atualizar a sua própria UI quando terminar.

## Mecânicas, tuning e danos

O snapshot é recolhido da entidade **ao guardar na garagem ou usar `/park`**. SQL conserva o JSON completo. Na saída normal, no `/park` e no valet através de `ApplyPhoneVehicle`, o mesmo snapshot é aplicado: spoiler, mods, jantes, cores, extras, livery, neon, turbo, xenon, fumo, combustível, sujidade, saúde de motor/carroçaria/tanque e vidros/portas/pneus danificados. Mods/extras são aplicados antes da condição final para impedir uma reparação implícita.

As amolgadelas visuais são amostradas em até 17 pontos e reaplicadas de forma limitada; a física e o modelo GTA podem impedir uma reprodução exatamente igual. Dados antigos sem amostragem continuam a carregar os danos já guardados. Não há autosave contínuo de um veículo que permanece fora: após modificar numa oficina, guarde o veículo para atualizar o snapshot. Dados específicos de mecânicas em state bags/tabelas próprias exigem a integração dessa mecânica.

O telefone ou outro recurso não deve chamar `SetVehicleFixed`, limpar os danos, aplicar propriedades antigas nem repor o combustível/sujidade depois de `ApplyPhoneVehicle`. Nos adaptadores incluídos, a garagem não repara o carro ao entregá-lo.

## Referências

- [CodeM mPhone 2.5](https://codem.gitbook.io/codem-documentation/m-series/essentials/mphone-2.5); adaptador baseado nos ficheiros `garage/server.lua` e `garage/client.lua` fornecidos pelo proprietário.
- [LB Garage: código oficial](https://github.com/lbphone/files/blob/main/lb-phone/server/apps/framework/garage.lua), [API servidor](https://docs.lbscripts.com/phone/custom-framework/server/) e [API cliente](https://docs.lbscripts.com/phone/custom-framework/client/).


## Vehiclekeys v1.2.0

QS: a chave pode ter sido escrita por outro recurso (stand, leilão) com outra grafia — matrícula crua de 8 caracteres com espaços finais, aparada ou sem espaços, e modelo em display name, minúsculas ou spawn name. A bridge consulta `GetKey` sobre essas grafias e opera na que existe: dar chaves reconhece a chave existente em vez de duplicar ou falhar (`already_has_key`), e remover apaga a grafia realmente guardada. Remover uma chave que nenhuma grafia confirma é um sucesso silencioso — o estado final «sem chave» já se verifica — e deixa de gerar `key_not_found` na consola do qs-vehiclekeys. Nas gerações antigas (exports com booleano e comparação exata de metadata) um `GiveKeys` recusado volta a sondar e tenta as restantes grafias; na v3 (fire-and-forget, match só por matrícula normalizada) o envio conta como êxito e a espera de chaves confirma a propagação com a grafia registada, sem sondar a matriz completa em cada iteração. Sem export `GetKey` (forks muito antigos), mantém-se a chamada única, com retries nas outras grafias apenas perante um `false` explícito.

Sistemas adicionados nesta versão:

| Sistema | Integração utilizada |
| --- | --- |
| ak47_vehiclekeys | Servidor: `GiveKey(source, plate)` / `RemoveKey(source, plate)` com `HasKey(source, plate)` antes — nunca duplica o item nem remove o que não existe. Espera de chaves: `HasKey(plate)` no cliente. |
| tgiann-hotwire | Servidor: `GiveKeyPlate(source, plate, false)` (`isNew=false` não invalida cópias existentes). **Não há API de remoção** — por desenho as chaves persistem; configurar `extraServerRemoveEvents`/`extraClientRemoveEvents` se a versão instalada tiver remoção própria. Espera: `HaveKeyPlate(plate)` no cliente. |
| brutal_keys | Eventos servidor documentados `brutal_keys:server:addVehicleKey(source, plate, label)` / `brutal_keys:server:removeKey(source, plate, true)`; o id e o label da chave de veículo são a matrícula. Espera: `getPlayerKey(plate)` no cliente. |
| mono_carkeys | Servidor: `InventoryKeys('add'|'remove', { plate, player })`. Espera: `GetPlayerKey(vehicle)` no cliente. |
| mk_vehiclekeys | Servidor por entidade: `AddKey(vehicle, source)` / `RemoveKey(vehicle, source)` com `HasKey` antes (idempotente). Requer entidade viva, como o Qbox. Espera: `HasKey(vehicle)` no cliente. |
| t1ger_keys | Híbrido: `UpdateKeysToDatabase(plate, true|false)` no servidor (flag em `owned_vehicles` — inócuo para veículos de frota sem linha própria) + chave temporária no cliente `GiveTemporaryKeys(plate, nome, 'garage')`; a remoção temporária usa `t1ger_keys:deleteCarKeys`. |
| F_RealCarKeysSystem | Relay cliente: `F_RealCarKeysSystem:generateVehicleKeys` (evento servidor, item para quem chama) / `F_RealCarKeysSystem:removeVehicleKeysByPlate` (evento cliente), com a matrícula tal como está no veículo. |
| xd_locksystem | Relay cliente: `SetVehicleKey(plate)` / `SetVehicleKey(plate, true)`. Um único portador por matrícula: dar move a chave para este jogador, remover limpa-a para todos; estado em memória (perde-se no restart do recurso). Espera: `GetVehicleData(plate) == 'self'`. |
| esx_vehiclelock | Sem API de chaves: o bloqueio vem da própria linha em `owned_vehicles`. A garagem não chama nada e reporta êxito; matrícula e `owner` têm de coincidir com a BD. |

`codem-vehiclekeys` e `rcore_carkeys` não têm documentação nem produto público (o CodeM faz bridge para outros sistemas de chaves; as chaves rcore vivem no rcore_garage). Builds privadas integram-se com `extraServerEvents`/`extraClientEvents` e os hooks de remoção correspondentes.

A venda (`Vehicles.Transferred`) sem entidade viva passou a revogar/atribuir com a matrícula guardada na base de dados em vez da chave normalizada sem espaços — providers por matrícula voltam a encontrar a chave do vendedor e do comprador.

Referências: [ak47](https://docs.menanak47.com/multi-framework/ak47_vehiclekeys/exports/server.md), [tgiann](https://docs.tgiann.com/scripts/tgiann-hotwire/exports), [Brutal](https://docs.brutalscripts.com/site/scripts/keys/exports-triggers), [mono](https://github.com/Mono-94/mono_carkeys), [mk](https://mankind-scripts.gitbook.io/documentation/scripts/vehicle-keys/exports), [T1GER](https://docs.t1ger.net/free-resources/t1ger-keys), [F-Development](https://forum.cfx.re/t/4941785), [xd](https://github.com/LielXD/xd_locksystem), [esx_vehiclelock](https://github.com/esx-community/esx_vehiclelock), [QS v3](https://www.quasar-store.com/docs/vehiclekeys/commands-and-exports).

## Arranque do motor v1.0.6

Com QS, definir `Config.VehicleKeys.system = 'qs'`. O modo `auto` deteta recursos iniciados; se houver vários, mostra um aviso com a seleção e deve ser substituído pelo sistema efetivamente usado no servidor. Ter uma chave noutro provider não confirma acesso no provider selecionado.

A saída da garagem/impound liga o motor após a confirmação das chaves e a entrada do condutor. A opção antiga `Config.Garage.spawnEngineOn` deixou de controlar a entrega. Os adaptadores CodeM/LB deixam o motor ligado também após a saída do NPC; é necessário substituir as cópias dos adaptadores instaladas no telefone.

QS `GetKey(plate, displayName)`, QB `HasKeys(plate)` e Qbox `HasKeys(entity)` são consultados dentro do mesmo limite de espera para aguardar a propagação das chaves. Outros sistemas usam a confirmação da API de atribuição. Forks antigos sem o export de consulta usam a confirmação existente e registam um aviso; um resultado negativo não é ignorado.

O motor não é reparado nem o depósito abastecido: um motor destruído ou combustível vazio pode impedir o arranque. Falhas de integração são avisadas sem bloquear permanentemente o arranque, duplicar chaves ou criar outra entidade.

Referência do sinalizador de arranque: [Cfx SET_VEHICLE_ENGINE_ON](https://github.com/citizenfx/natives/blob/master/VEHICLE/SetVehicleEngineOn.md).

## Vehiclekeys v1.0.2

O erro `attempt to call a nil value (field 'GetDisplayNameFromVehicleModel')` foi tratado separando os lados: a conversão de hash para nome de modelo do QS existe apenas no cliente e verifica se a native está disponível. O servidor entrega um pedido dirigido ao proprietário validado; não chama `GiveKeys(source, plate)` como se fosse um export servidor QS.

As chaves são atribuídas uma vez por aprovação. `ApplyPhoneVehicle` aplica propriedades e confirma o spawn; `WaitForVehicleKeys` aguarda o resultado antes de ligar o motor. Se usou `{deferConfirm=true}`, o telefone tem de chamar `ConfirmPhoneVehicle` no servidor antes de esperar. A falha de chaves mantém o veículo já criado fora e com motor desligado, sem cancelar o estado nem criar uma segunda cópia. Os adaptadores CodeM/LB incluídos fazem esta sequência.

| Sistema | Integração utilizada |
| --- | --- |
| QB | Servidor: `GiveKeys(source, plate)` / `RemoveKeys(source, plate)`; atualiza o estado oficial, sem evento legado de aquisição com argumento errado. |
| Qbox | Servidor: `GiveKeys(source, entity, true)` / `RemoveKeys(source, entity, true)`. Requer entidade válida; nunca passa matrícula no lugar da entidade. |
| QS | Cliente dirigido pelo servidor: `GetKey(plate, displayName)`, `GiveKeys(plate, displayName, true)` / `RemoveKeys(plate, displayName)`. Consulta chave existente antes de dar outra. |
| MrNewb | Servidor: `GiveKeysByPlate` / `RemoveKeysByPlate`. |
| Wasabi | Servidor: `GiveKey(source, plate)` / `RemoveKey(source, plate)`. |
| Renewed | Servidor: `addKey(source, plate)` / `removeKey(source, plate)`. |
| Jaksam vehicles_keys | Servidor: `giveVehicleKeysToPlayerId(source, plate, 'temporary')` / `removeKeysFromPlayerId(source, plate)`. |
| Codesign | Eventos cliente documentados `cd_garage:AddKeys` / `cd_garage:RemoveKeys`. |
| okokGarage | Eventos servidor documentados enviados pelo cliente destinatário, mantendo o source correto. |
| TebIT ti_vehicleKeys | Servidor: `createKey(source, plate)`. A API oficial consultada não documenta remoção; configurar um hook de remoção da versão instalada. |

`Config.VehicleKeys.removeOnStore=false` mantém chaves apenas no armazenamento normal. Venda, apreensão e devolução/recall de frota forçam a revogação quando o provider a suporta. Qbox não pode revogar por entidade se ela já desapareceu; o código não inventa uma API por matrícula. Providers que só oferecem eventos confirmam o envio do evento, não o processamento interno do recurso externo.

Use `extraClientEvents` / `extraServerEvents` para hooks de atribuição e `extraClientRemoveEvents` / `extraServerRemoveEvents` para hooks de remoção. Assinaturas: cliente `(plate, modelHash, entity)`; servidor `(source, plate, modelHash, entity)`. A entidade pode ser `0` quando já não existe. Matrículas perdem apenas espaços nas extremidades; os espaços internos são preservados. Não configure hooks que repitam a mesma atribuição do provider padrão.

Selecione explicitamente `Config.VehicleKeys.system` quando tiver vários sistemas instalados. Deteção e cache recuperam de recursos iniciados tarde ou reiniciados. A bridge de combustível também recupera desses casos e rejeita NaN/infinito, preservando o nível válido atual.

Referências principais: [QS](https://www.quasar-store.com/docs/vehiclekeys/commands-and-exports), [Qbox](https://docs.qbox.re/resources/qbx_vehiclekeys/exports/server), [QB](https://github.com/qbcore-fivem/qb-vehiclekeys/blob/main/server.lua), [Wasabi](https://docs.wasabiscripts.com/advanced-series/wasabi-carlock/exports/), [MrNewb](https://mrnewbs-scrips.gitbook.io/guide/vehiclekeys/vehicle-keys-exports/server-exports), [Jaksam](https://documentation.jaksam-scripts.com/vehicles-keys/server/give-keys-to-player-id), [TebIT](https://tebit.gitbook.io/tebit-wiki/resources/vehicle-keys-and-security). Testes automatizados simulam as APIs; é necessário validar as versões instaladas dentro do FiveM.
