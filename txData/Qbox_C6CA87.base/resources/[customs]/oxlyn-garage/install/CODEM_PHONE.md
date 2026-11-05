# CodeM Phone: aplicação Valet

Adaptador para a API `Garage`/`GarageClient` dos dois ficheiros fornecidos
(`exports/garage/server.lua` e `exports/garage/client.lua`). Os ficheiros originais
da CodeM não são substituídos. Estes exemplos devem ser instalados **no recurso
do telefone**, não no manifesto da OXLYN.

1. Copiar `codem_phone_server.lua` e `codem_phone_client.lua` para uma pasta do
   telefone, por exemplo `custom/oxlyn/`.
2. No `fxmanifest.lua` do telefone, carregar cada adaptador **depois** do respetivo
   ficheiro original, que publica `Garage` ou `GarageClient` em `_G`:

   ```lua
   server_scripts {
       -- ... dependências e ficheiros existentes ...
       'exports/garage/server.lua',
       'custom/oxlyn/codem_phone_server.lua',
   }
   client_scripts {
       -- ... dependências e ficheiros existentes ...
       'exports/garage/client.lua',
       'custom/oxlyn/codem_phone_client.lua',
   }
   ```

   Se os originais já forem carregados por uma lista/padrão, não os carregar uma
   segunda vez. Acrescentar apenas o adaptador na posição correta.
3. Na configuração partilhada do telefone:

   ```lua
   Config.Valet.GarageScript = 'oxlyn-garage'
   Config.Valet.OxlynResource = 'oxlyn-garage' -- nome REAL da pasta em execução
   Config.Valet.OxlynMaxDistance = 250.0 -- igual a Config.Phone.valet.maxDistance
   ```

   Por exemplo, usar `oxlyn-garage-OPENSOURCE` em `OxlynResource` se esse for o nome
   do recurso instalado. `GarageScript = 'auto'` também deteta a OXLYN quando o
   recurso configurado estiver iniciado. Iniciar a OXLYN antes do telefone.
4. Ativar `Config.Phone.enabled` e `Config.Phone.valet.enabled` na OXLYN. Manter
   `Config.Phone.valet.maxDistance` suficientemente grande para os nós de trânsito
   usados pela CodeM (predefinição OXLYN: 250 metros; entrega nativa: 75–150 m).

O adaptador usa `GetPhoneVehicles(source, 'codem')`, reserva através de
`PreparePhoneVehicle`, aplica as propriedades com `ApplyPhoneVehicle` e confirma
através de `ConfirmPhoneVehicle`. A cobrança mantém-se no telefone; a reserva
pede `charge = false` exclusivamente pelo export de servidor. Não colocar essa
opção numa chamada de cliente nem somar novamente a taxa OXLYN.

`mods` contém o JSON completo guardado e um marcador `__oxlynPhone`. Preservar
esse campo ao construir a resposta para o cliente. O cliente remove o marcador
antes de aplicar as propriedades. Não passar apenas `statistics`: são valores
para apresentação, não o estado completo do veículo.

As propriedades são aplicadas uma única vez antes de conduzir: spoiler, restantes
mods, combustível, sujidade e danos disponíveis no estado guardado. O adaptador
OXLYN não executa o `SetVehicleDirtLevel(vehicle, 0.0)` da entrega original e não
reaplica o estado inicial após a viagem; uma colisão durante a entrega continua
a contar como dano novo. As outras garagens continuam a usar os métodos originais.

Se a entrega não chegar ao destino no prazo, o veículo confirmado permanece no
mundo e o cliente marca a sua posição. Não é criada outra cópia nem alterado o
estado para guardado. Uma falha antes da aplicação tenta remover a entidade e
cancela apenas a reserva do jogador que a pediu.

## Verificação no servidor de desenvolvimento

- Confirmar a lista de veículos próprios e a indisponibilidade de veículos
  apreendidos, já fora, estacionados em `/park` ou bloqueados por contrato.
- Guardar um carro com spoiler, danos e combustível parcial; pedir o valet e
  verificar o estado antes/depois da entrega, sem reparações automáticas.
- Testar os modos de spawn que o telefone usa, com e sem condutor NPC.
- Testar falha de modelo, falha de controlo de rede, cancelamento, pedido
  duplicado e saída do jogador; confirmar ausência de duplicados e de dupla taxa.

O fluxo completo de faturação/spawn do telefone não foi fornecido: estes snippets
foram escritos para os métodos presentes nos dois adaptadores recebidos. Versões
que removam `mods` da resposta, não chamem `GarageClient.SpawnAndDeliver`, ou
atualizem diretamente a base de dados fora de `Garage.SetVehicleOutside` precisam
de adaptar também esse ponto. Validar numa instância FiveM antes de produção.


### Atualização OXLYN 1.0.2

Substituir também o adaptador cliente por esta versão: aguarda `WaitForVehicleKeys` após a confirmação e antes de ligar o motor/NPC. Quando a chave falha, o veículo confirmado fica fora e localizado, com motor desligado e aviso OXLYN; não eliminar, cancelar ou devolver a taxa dessa entidade já confirmada. Esta recuperação devolve sucesso ao telefone para impedir que versões externas tentem desfazer uma entrega já confirmada.


### Atualização OXLYN 1.0.6

Substituir novamente o adaptador cliente instalado no telefone pelo ficheiro deste pacote. Esta versão deixa o motor ligado após a entrega/saída do NPC e não mantém o bloqueio nativo de arranque quando a chave demora ou falha. Atualizar apenas a pasta da garagem não altera a cópia instalada no telefone. A espera no OXLYN verifica também a presença das chaves no QS/QB/Qbox antes da condução. Danos e combustível continuam a ser preservados.
