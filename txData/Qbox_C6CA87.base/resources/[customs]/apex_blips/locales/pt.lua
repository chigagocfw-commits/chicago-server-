--[[
    Apex Blips / Português (pt-PT)

    Tradução completa do locales/en.lua. Os %s / %d são preenchidos pelo
    código. Mantém-nos, podes movê-los dentro da frase.
]]

Locales = Locales or {}

Locales['pt'] = {

    ----------------------------------------------------------------------------
    -- Notificações em jogo (chat)
    ----------------------------------------------------------------------------
    n_no_perm       = 'Não tens permissão para usar o Blip Studio.',
    n_saved         = 'Blip "%s" guardado.',
    n_deleted       = 'Blip apagado.',
    n_toggle_on     = 'Blips personalizados de volta no teu mapa.',
    n_toggle_off    = 'Blips personalizados escondidos no teu mapa (só para ti).',
    n_import_done   = '%d blips importados.',
    n_import_fail   = 'Importação falhou: %s',
    n_image_saved   = 'Imagem "%s" guardada na biblioteca.',
    n_image_deleted = 'Imagem removida da biblioteca.',
    n_image_in_use  = 'Essa imagem é usada por %d blips. Muda-os primeiro.',
    n_image_limit   = 'Biblioteca de imagens cheia (%d).',
    n_store_limit   = 'Limite de blips atingido (%d).',
    n_rate          = 'Calma.',
    n_bad_payload   = 'Essa alteração foi rejeitada pelo servidor.',

    -- Escolher no mapa
    n_pick_hint     = 'Coloca um waypoint no mapa para posicionar o blip. Fecha o mapa para cancelar.',
    n_pick_done     = 'Posição escolhida no mapa.',
    n_pick_cancel   = 'Escolha no mapa cancelada.',
    n_waypoint_none = 'Não há waypoint. Abre o mapa e coloca um primeiro.',
    keybind_desc    = 'Abrir o Blip Studio',

    ----------------------------------------------------------------------------
    -- Shell
    ----------------------------------------------------------------------------
    app_title       = 'Blip Studio',
    app_kicker      = 'APEX',
    chip_blips      = 'blips',
    chip_unsaved    = 'POR GUARDAR',
    btn_close       = 'Fechar',
    hint_esc        = 'fechar',
    hint_save       = 'guardar',
    hint_nav        = 'navegar',

    tab_blips       = 'Blips',
    tab_editor      = 'Editor',
    tab_images      = 'Imagens',
    tab_dev         = 'Developer',

    ----------------------------------------------------------------------------
    -- Lista de blips
    ----------------------------------------------------------------------------
    search_ph       = 'Procurar blips…',
    new_blip        = 'Novo blip',
    list_empty_t    = 'Ainda não há blips',
    list_empty_d    = 'Cria o teu primeiro blip: escolhe um sprite, envia um logótipo ou gera um badge com emoji.',
    list_none_match = 'Nada corresponde a essa pesquisa.',
    chip_zone       = 'zona',
    chip_jobs       = 'jobs',
    chip_private    = 'privado',
    chip_off        = 'off',
    chip_image      = 'imagem',
    chip_badge      = 'badge',
    act_edit        = 'Editar',
    act_dup         = 'Duplicar',
    act_on          = 'Ativar',
    act_off         = 'Desativar',
    act_del         = 'Apagar',
    act_locate      = 'Marcar waypoint neste blip',

    ----------------------------------------------------------------------------
    -- Editor
    ----------------------------------------------------------------------------
    ed_new_t        = 'Novo blip',
    ed_edit_t       = 'A editar',
    ed_empty_t      = 'Nenhum blip aberto',
    ed_empty_d      = 'Cria um novo, ou clica num blip no mapa ou na lista.',
    sec_icon        = 'Ícone',
    sec_identity    = 'Identidade',
    sec_position    = 'Posição',
    sec_behaviour   = 'Comportamento',
    sec_zone        = 'Zona no mapa',
    sec_visibility  = 'Visibilidade',

    icon_sprite     = 'Sprite GTA',
    icon_image      = 'Imagem',
    icon_badge      = 'Badge',
    pick_sprite     = 'Escolher sprite',
    sprite_hint     = 'Ícones nativos, coloríveis e sempre nítidos.',
    image_hint      = 'Qualquer imagem vira um blip a sério. Um slot por imagem distinta; blips que partilham a imagem partilham o slot.',
    badge_hint      = 'Emoji ou até 3 caracteres num disco colorido, gerado como imagem.',
    pick_image      = 'Escolher da biblioteca',
    upload_image    = 'Enviar imagem',
    img_shape       = 'Forma da imagem',
    shape_original  = 'Original',
    img_shape_hint  = 'Arredondado e Círculo recortam a imagem para encher a forma.',
    emoji_pick      = 'Escolher um emoji ou ícone',
    emoji_tab_emoji = 'Emojis',
    emoji_tab_fa    = 'Font Awesome',
    emoji_search_ph = 'Procurar ícones por nome…',
    emoji_custom_ph = 'Falta algum? Cola um emoji, ou um código fa tipo f1b9',
    emoji_custom_use= 'Usar',
    fa_count        = '%d de %d ícones',
    em_smileys      = 'Smileys',
    em_picto        = 'Pictogramas',
    em_transport    = 'Transporte e mapa',
    em_extra        = 'Mais símbolos',
    em_extra2       = 'Ainda mais',
    em_symbols      = 'Símbolos clássicos',
    em_dingbats     = 'Dingbats',
    em_text         = 'Ícones de texto',
    badge_text_ph   = '🍕 ou ABC',
    badge_bg        = 'Disco',
    badge_fg        = 'Tinta',
    badge_shape     = 'Forma',
    shape_circle    = 'Círculo',
    shape_rounded   = 'Arredondado',
    shape_square    = 'Quadrado',
    shape_nobg      = 'Sem fundo',
    badge_bake      = 'Gerar badge para a biblioteca',
    no_icon_yet     = 'Ainda não escolheste um ícone.',

    f_name          = 'Nome',
    f_name_ph       = 'Aparece na legenda do mapa',
    f_colour        = 'Cor',
    colour_hint     = 'Tinta do GTA. 0 mantém o sprite sem tinta. Blips de imagem nunca são tingidos.',
    f_scale         = 'Escala',
    f_alpha         = 'Opacidade',

    f_x             = 'X',
    f_y             = 'Y',
    f_z             = 'Z',
    btn_mypos       = 'Minha posição',
    btn_waypoint    = 'Usar waypoint',
    btn_pickmap     = 'Escolher no mapa',
    pickmap_hint    = 'Abre o mapa. Coloca um waypoint onde o blip deve ficar.',

    f_shortrange    = 'Curto alcance',
    shortrange_hint = 'Só aparece no minimapa quando estás perto. Off = sempre na borda do minimapa.',
    f_category      = 'Categoria',
    cat_1           = 'Normal',
    cat_2           = 'Mostra distância',
    cat_10          = 'Propriedade',
    cat_11          = 'Propriedade própria',
    f_display       = 'Mostrar em',
    disp_2          = 'Minimapa + mapa',
    disp_3          = 'Só no mapa (pausa)',
    disp_5          = 'Só no minimapa',
    f_flash         = 'A piscar',
    f_route         = 'Rota GPS',
    route_hint      = 'Desenha uma rota até ao blip para todos os que o veem.',
    f_route_colour  = 'Cor da rota',

    zone_mode       = 'Zona',
    zone_none       = 'Nenhuma',
    zone_radius     = 'Círculo',
    zone_area       = 'Retângulo',
    f_radius        = 'Raio',
    f_width         = 'Largura',
    f_height        = 'Altura',
    f_rot           = 'Rotação',
    f_zone_colour   = 'Cor da zona',
    f_zone_alpha    = 'Opacidade da zona',
    f_zone_events   = 'Disparar eventos de entrada / saída',
    zone_events_hint= 'Outros resources podem ouvir: apex_blips:client:zoneEnter / zoneExit (client) e apex_blips:zone (server). Vê a tab Developer.',

    vis_everyone    = 'Todos',
    vis_jobs        = 'Jobs',
    vis_private     = 'Só eu',
    f_jobs          = 'Nomes dos jobs',
    f_jobs_ph       = 'police, ambulance…  (Enter adiciona)',
    vis_jobs_hint   = 'Só jogadores com um destes jobs da framework recebem o blip.',
    vis_private_hint= 'Só tu recebes este blip, um marcador pessoal.',

    btn_save        = 'Guardar blip',
    btn_create      = 'Criar blip',
    btn_cancel      = 'Cancelar',
    btn_delete      = 'Apagar',

    ----------------------------------------------------------------------------
    -- Coluna de preview
    ----------------------------------------------------------------------------
    prev_t          = 'Preview ao vivo',
    prev_map        = 'Mapa',
    tip_world       = 'Mostrar todos os blips do jogo (de todos os scripts)',
    t_world_n       = '%d blips do jogo no mapa.',
    prev_map_hint   = 'Clica no mapa (ou arrasta o marcador) para mover o blip.',
    prev_map_off    = 'Tiles do mapa indisponíveis (sem internet).',
    prev_minimap    = 'Minimapa',
    prev_legend     = 'Legenda do mapa',
    prev_none       = 'Escolhe um ícone para o ver aqui.',
    slotbar_t       = 'Slots de imagem',
    slotbar_d       = '%d de %d em uso',

    ----------------------------------------------------------------------------
    -- Modal do catálogo de sprites
    ----------------------------------------------------------------------------
    sp_title        = 'Catálogo de sprites do GTA',
    sp_search_ph    = 'Procurar por nome ou id…',
    sp_count        = '%d de %d sprites',
    sp_cap          = 'A mostrar os primeiros %d. Afina a pesquisa.',
    sp_fail         = 'O catálogo de sprites não carregou. Reinicia o resource.',

    ----------------------------------------------------------------------------
    -- Tab de imagens
    ----------------------------------------------------------------------------
    img_t           = 'Biblioteca de imagens',
    img_d           = 'Os ícones vivem aqui uma única vez. Qualquer número de blips pode apontar para a mesma imagem e partilhar um só slot.',
    img_empty_t     = 'A biblioteca está vazia',
    img_empty_d     = 'Envia um logótipo ou gera um badge no editor. Os ícones guardados aparecem aqui.',
    img_name_ph     = 'Nome da imagem',
    img_used        = 'usada por %d',
    img_unused      = 'sem uso',
    img_upload      = 'Enviar',
    img_del_t       = 'Apagar esta imagem?',
    img_del_d       = 'Os blips que a usam têm de ser mudados primeiro. O servidor recusa deixá-los órfãos.',

    ----------------------------------------------------------------------------
    -- Tab Developer
    ----------------------------------------------------------------------------
    dev_t           = 'Developer',
    dev_d           = 'Tudo o que o estúdio faz é scriptável. Escolhe um blip em cima e os snippets levam o id e os dados reais dele.',
    dev_copy        = 'Copiar',
    dev_copied      = 'Copiado.',
    dev_pick        = 'Blip',
    dev_pick_none   = 'Ainda não há blips. Cria um primeiro.',
    dev_thiscode    = 'Este blip, em código (AddBlip)',
    dev_sn_reg      = 'RegisterImage (qualquer imagem, depois usa-a como ícone)',
    dev_sn_local    = 'AddLocalBlip (só para este jogador, nunca guardado)',
    dev_sn_evc      = 'Eventos de zona (client)',
    dev_sn_evs      = 'Eventos de zona (server)',
    dev_srv_t       = 'Exports de servidor',
    dev_cli_t       = 'Exports de client',
    dev_ev_t        = 'Eventos',
    dev_export_t    = 'Exportar todos os blips (JSON)',
    dev_export_btn  = 'Copiar JSON',
    dev_import_t    = 'Importar blips (JSON)',
    dev_import_ph   = 'Cola aqui um export JSON…',
    dev_import_btn  = 'Importar',

    ----------------------------------------------------------------------------
    -- Toasts / modais do estúdio
    ----------------------------------------------------------------------------
    t_saved         = 'Blip guardado.',
    t_created       = 'Blip criado.',
    t_deleted       = 'Blip apagado.',
    t_img_saved     = 'Imagem guardada.',
    t_img_deleted   = 'Imagem apagada.',
    t_img_type      = 'Esse ficheiro não é uma imagem.',
    t_img_big       = 'A imagem continua pesada demais depois de reduzida (máx %d KB).',
    t_need_name     = 'Dá um nome ao blip primeiro.',
    t_need_icon     = 'Escolhe um ícone primeiro.',
    t_need_image    = 'Escolhe ou envia uma imagem primeiro.',
    t_need_badge    = 'Escreve alguma coisa para o badge primeiro.',
    t_bad_import    = 'Isso não é um export de blips válido.',
    t_import_ok     = '%d blips enviados para o servidor.',
    t_pick_wait     = 'À espera do mapa…',
    t_no_jobs       = 'Adiciona pelo menos um job, ou volta a pôr a visibilidade em Todos.',

    t_img_replaced  = 'Imagem substituída. Todos os blips que a usam foram atualizados.',
    t_img_busy      = 'Um de cada vez. Tenta outra vez daqui a um instante.',
    t_img_limit     = 'A biblioteca está cheia (máximo %d).',
    t_img_fail      = 'Não foi possível guardar essa imagem.',
    t_img_timeout   = 'O servidor não respondeu. A imagem não foi guardada.',
    t_img_progress  = 'A enviar imagens… %s',
    t_img_batch_ok  = '%d imagens guardadas.',
    t_img_batch_part = '%d de %d imagens guardadas.',
    t_img_room      = 'Só cabem mais %d na biblioteca. As restantes foram ignoradas.',
    t_no_perm       = 'Não tens permissão para editar blips.',
    act_replace     = 'Substituir imagem',
    act_replace_used = 'Substituir imagem (atualiza %d blips)',
    modal_del_t     = 'Apagar este blip?',
    modal_del_d     = 'Remove-o para todos os jogadores. Não há undo.',
    modal_ok        = 'Apagar',
    modal_cancel    = 'Cancelar',
}
