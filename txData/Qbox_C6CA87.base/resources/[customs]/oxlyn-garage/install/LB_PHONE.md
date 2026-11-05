# LB Phone — app Garage nativa

Adaptador baseado nos ficheiros públicos oficiais do LB Phone consultados em 24/09/2026. Mantém a app Garage existente, a lista, a localização e o valet com NPC opcional. Requer teste no servidor com a versão de LB instalada.

1. Faz backup dos dois ficheiros originais do **lb-phone**.
2. Substitui `lb-phone/server/apps/framework/garage.lua` pelo conteúdo de `lb_phone_server.lua`.
3. Substitui `lb-phone/client/apps/framework/garage.lua` pelo conteúdo de `lb_phone_client.lua`.
4. Estes ficheiros já são carregados pelo manifest normal do LB. **Não os acrescentes como scripts adicionais** e não os carregues no OXLYN: o LB recusa registar callbacks duplicados.
5. Mantém o framework habitual no LB. Em `lb-phone/config/config.lua` define:

```lua
Config.Valet.OxlynResource = 'oxlyn-garage' -- nome REAL da pasta em execução
Config.Valet.Enabled = true
Config.Valet.Price = 100       -- uma cobrança, feita pelo LB
Config.Valet.Drive = true      -- false: entrega sem motorista
Config.Valet.FixTakeOut = false
Config.Valet.DisableDamages = false
```

`Config.ServerSideSpawn` pode continuar em `true` ou `false`. Inicia o OXLYN antes do LB Phone. Usa apenas uma edição do OXLYN e ativa `Config.Phone.enabled` e `Config.Phone.valet.enabled`. O adaptador procura um ponto de estrada livre até 250 m; mantém `Config.Phone.valet.maxDistance = 250.0` ou superior. Sem ponto seguro, o pedido falha antes de cobrar.

O servidor OXLYN valida propriedade, estado guardado, acesso à garagem, contratos, apreensão, duplicados e posição. `PreparePhoneVehicle` é chamado com `charge = false` porque o LB cobra `Config.Valet.Price`. Falhas anteriores à confirmação cancelam a reserva e devolvem a cobrança quando o cancelamento é seguro. Depois da confirmação, o veículo continua fora mesmo que o NPC não consiga chegar: fica localizável, sem duplicação nem reembolso automático.

São aplicadas as propriedades completas uma única vez antes da condução. O adaptador não repara, limpa nem abastece o veículo e não repõe os danos após o trajeto. O NPC e a procura de entidade têm limites de tempo. A app recebe `false` quando a aplicação das propriedades falha. O botão de fecho remoto continua sem implementação, tal como o ponto de integração padrão do LB; usa o teu sistema de chaves se precisares dessa função.

Confirma em jogo: lista/estado, localizar, preço e reembolso por falha, carro tunado/danificado/com pouco combustível, matrículas com espaços, NPC ligado/desligado, ambos os modos de spawn, veículo já fora, apreendido e pedido repetido. Testes automáticos com mocks não substituem OneSync/CEF.

Referências oficiais: [contrato server](https://docs.lbscripts.com/phone/custom-framework/server/), [contrato client](https://docs.lbscripts.com/phone/custom-framework/client/), [callbacks LB](https://github.com/lbphone/files/blob/main/lb-phone/lib/server/registerCallbacks.lua), [Garage server original](https://github.com/lbphone/files/blob/main/lb-phone/server/apps/framework/garage.lua), [Garage client original](https://github.com/lbphone/files/blob/main/lb-phone/client/apps/framework/garage.lua).


### Atualização OXLYN 1.0.2

Substituir também o adaptador cliente por esta versão: aguarda `WaitForVehicleKeys` após a confirmação e antes de ligar o motor/NPC. Quando a chave falha, o veículo confirmado fica fora e localizado, com motor desligado e aviso OXLYN; não eliminar, cancelar ou devolver a taxa dessa entidade já confirmada. Esta recuperação devolve sucesso ao telefone para impedir que versões externas tentem desfazer uma entrega já confirmada.


### Atualização OXLYN 1.0.6

Substituir novamente o adaptador cliente instalado no telefone pelo ficheiro deste pacote. Esta versão deixa o motor ligado após a entrega/saída do NPC e não mantém o bloqueio nativo de arranque quando a chave demora ou falha. Atualizar apenas a pasta da garagem não altera a cópia instalada no telefone. A espera no OXLYN verifica também a presença das chaves no QS/QB/Qbox antes da condução. Danos e combustível continuam a ser preservados.
