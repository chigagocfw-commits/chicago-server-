--[[
    Apex Blips / English (primary language)

    Keys are grouped the way the interface is grouped. %s / %d are filled by
    the code. Keep them, you can move them around inside the sentence.
]]

Locales = Locales or {}

Locales['en'] = {

    ----------------------------------------------------------------------------
    -- In-game notifications (chat)
    ----------------------------------------------------------------------------
    n_no_perm       = 'You are not allowed to use the Blip Studio.',
    n_saved         = 'Blip "%s" saved.',
    n_deleted       = 'Blip deleted.',
    n_toggle_on     = 'Custom blips are back on your map.',
    n_toggle_off    = 'Custom blips hidden on your map (only for you).',
    n_import_done   = '%d blips imported.',
    n_import_fail   = 'Import failed: %s',
    n_image_saved   = 'Image "%s" saved to the library.',
    n_image_deleted = 'Image removed from the library.',
    n_image_in_use  = 'That image is used by %d blips. Repoint them first.',
    n_image_limit   = 'Image library is full (%d).',
    n_store_limit   = 'Blip limit reached (%d).',
    n_rate          = 'Slow down.',
    n_bad_payload   = 'That change was rejected by the server.',

    -- Pick-on-map flow
    n_pick_hint     = 'Place a waypoint on the map to position the blip. Close the map to cancel.',
    n_pick_done     = 'Position picked from the map.',
    n_pick_cancel   = 'Map pick cancelled.',
    n_waypoint_none = 'No waypoint set. Open the map and place one first.',
    keybind_desc    = 'Open the Blip Studio',

    ----------------------------------------------------------------------------
    -- Shell
    ----------------------------------------------------------------------------
    app_title       = 'Blip Studio',
    app_kicker      = 'APEX',
    chip_blips      = 'blips',
    chip_unsaved    = 'UNSAVED',
    btn_close       = 'Close',
    hint_esc        = 'close',
    hint_save       = 'save',
    hint_nav        = 'navigate',

    tab_blips       = 'Blips',
    tab_editor      = 'Editor',
    tab_images      = 'Images',
    tab_dev         = 'Developer',

    ----------------------------------------------------------------------------
    -- Blip list
    ----------------------------------------------------------------------------
    search_ph       = 'Search blips…',
    new_blip        = 'New blip',
    list_empty_t    = 'No blips yet',
    list_empty_d    = 'Create your first blip: pick a sprite, upload a logo or bake an emoji badge.',
    list_none_match = 'Nothing matches that search.',
    chip_zone       = 'zone',
    chip_jobs       = 'jobs',
    chip_private    = 'private',
    chip_off        = 'off',
    chip_image      = 'image',
    chip_badge      = 'badge',
    act_edit        = 'Edit',
    act_dup         = 'Duplicate',
    act_on          = 'Enable',
    act_off         = 'Disable',
    act_del         = 'Delete',
    act_locate      = 'Set waypoint to this blip',

    ----------------------------------------------------------------------------
    -- Editor
    ----------------------------------------------------------------------------
    ed_new_t        = 'New blip',
    ed_edit_t       = 'Editing',
    ed_empty_t      = 'No blip open',
    ed_empty_d      = 'Create a new one, or click a blip on the map or in the list.',
    sec_icon        = 'Icon',
    sec_identity    = 'Identity',
    sec_position    = 'Position',
    sec_behaviour   = 'Behaviour',
    sec_zone        = 'Map zone',
    sec_visibility  = 'Visibility',

    icon_sprite     = 'GTA sprite',
    icon_image      = 'Image',
    icon_badge      = 'Badge',
    pick_sprite     = 'Choose sprite',
    sprite_hint     = 'Native icons, tintable and always crisp.',
    image_hint      = 'Any picture becomes a real blip. One image slot per distinct picture; blips sharing a picture share the slot.',
    badge_hint      = 'Emoji or up to 3 characters on a coloured disc, baked into an image.',
    pick_image      = 'Choose from library',
    upload_image    = 'Upload image',
    img_shape       = 'Image shape',
    shape_original  = 'Original',
    img_shape_hint  = 'Rounded and Circle crop the picture to fill the shape.',
    emoji_pick      = 'Pick an emoji or icon',
    emoji_tab_emoji = 'Emojis',
    emoji_tab_fa    = 'Font Awesome',
    emoji_search_ph = 'Search icons by name…',
    emoji_custom_ph = 'Anything missing? Paste an emoji, or an fa code like f1b9',
    emoji_custom_use= 'Use',
    fa_count        = '%d of %d icons',
    em_smileys      = 'Smileys',
    em_picto        = 'Pictographs',
    em_transport    = 'Transport & map',
    em_extra        = 'More symbols',
    em_extra2       = 'Even more',
    em_symbols      = 'Classic symbols',
    em_dingbats     = 'Dingbats',
    em_text         = 'Text icons',
    badge_text_ph   = '🍕 or ABC',
    badge_bg        = 'Disc',
    badge_fg        = 'Ink',
    badge_shape     = 'Shape',
    shape_circle    = 'Circle',
    shape_rounded   = 'Rounded',
    shape_square    = 'Square',
    shape_nobg      = 'No disc',
    badge_bake      = 'Bake badge into library',
    no_icon_yet     = 'No icon chosen yet.',

    f_name          = 'Name',
    f_name_ph       = 'Shown in the pause-map legend',
    f_colour        = 'Colour',
    colour_hint     = 'GTA tint. 0 keeps the sprite untinted. Image blips always render untinted.',
    f_scale         = 'Scale',
    f_alpha         = 'Opacity',

    f_x             = 'X',
    f_y             = 'Y',
    f_z             = 'Z',
    btn_mypos       = 'My position',
    btn_waypoint    = 'Use waypoint',
    btn_pickmap     = 'Pick on map',
    pickmap_hint    = 'Opens the map. Place a waypoint where the blip should live.',

    f_shortrange    = 'Short range',
    shortrange_hint = 'Only appears on the minimap when you are nearby. Off = always on the minimap edge.',
    f_category      = 'Category',
    cat_1           = 'Default',
    cat_2           = 'Shows distance',
    cat_10          = 'Property',
    cat_11          = 'Owned property',
    f_display       = 'Show on',
    disp_2          = 'Minimap + map',
    disp_3          = 'Pause map only',
    disp_5          = 'Minimap only',
    f_flash         = 'Flashing',
    f_route         = 'GPS route',
    route_hint      = 'Draws a purple-style route to the blip for everyone who can see it.',
    f_route_colour  = 'Route colour',

    zone_mode       = 'Zone',
    zone_none       = 'None',
    zone_radius     = 'Circle',
    zone_area       = 'Rectangle',
    f_radius        = 'Radius',
    f_width         = 'Width',
    f_height        = 'Height',
    f_rot           = 'Rotation',
    f_zone_colour   = 'Zone colour',
    f_zone_alpha    = 'Zone opacity',
    f_zone_events   = 'Fire enter / exit events',
    zone_events_hint= 'Other resources can listen: apex_blips:client:zoneEnter / zoneExit (client) and apex_blips:zone (server). See the Developer tab.',

    vis_everyone    = 'Everyone',
    vis_jobs        = 'Jobs',
    vis_private     = 'Only me',
    f_jobs          = 'Job names',
    f_jobs_ph       = 'police, ambulance…  (Enter adds)',
    vis_jobs_hint   = 'Only players with one of these framework jobs receive the blip.',
    vis_private_hint= 'Only you receive this blip, a personal marker.',

    btn_save        = 'Save blip',
    btn_create      = 'Create blip',
    btn_cancel      = 'Cancel',
    btn_delete      = 'Delete',

    ----------------------------------------------------------------------------
    -- Preview column
    ----------------------------------------------------------------------------
    prev_t          = 'Live preview',
    prev_map        = 'Map',
    tip_world       = 'Show every game blip (from all scripts)',
    t_world_n       = '%d game blips shown.',
    prev_map_hint   = 'Click the map (or drag the marker) to move the blip.',
    prev_map_off    = 'Map tiles unavailable (no internet).',
    prev_minimap    = 'Minimap',
    prev_legend     = 'Pause-map legend',
    prev_none       = 'Pick an icon to preview it here.',
    slotbar_t       = 'Image slots',
    slotbar_d       = '%d of %d in use',

    ----------------------------------------------------------------------------
    -- Sprite picker modal
    ----------------------------------------------------------------------------
    sp_title        = 'GTA sprite catalogue',
    sp_search_ph    = 'Search by name or id…',
    sp_count        = '%d of %d sprites',
    sp_cap          = 'Showing the first %d. Refine the search.',
    sp_fail         = 'Sprite catalogue failed to load. Restart the resource.',

    ----------------------------------------------------------------------------
    -- Images tab
    ----------------------------------------------------------------------------
    img_t           = 'Image library',
    img_d           = 'Icons live here once. Any number of blips can point at the same image and share a single slot.',
    img_empty_t     = 'Library is empty',
    img_empty_d     = 'Upload a logo or bake a badge in the editor. Saved icons appear here.',
    img_name_ph     = 'Image name',
    img_used        = 'used by %d',
    img_unused      = 'unused',
    img_upload      = 'Upload',
    img_del_t       = 'Delete this image?',
    img_del_d       = 'Blips using it must be repointed first. The server refuses to orphan them.',

    ----------------------------------------------------------------------------
    -- Developer tab
    ----------------------------------------------------------------------------
    dev_t           = 'Developer',
    dev_d           = 'Everything the studio does is scriptable. Pick a blip above and the snippets carry its real id and data.',
    dev_copy        = 'Copy',
    dev_copied      = 'Copied.',
    dev_pick        = 'Blip',
    dev_pick_none   = 'No blips yet. Create one first.',
    dev_thiscode    = 'This blip, as code (AddBlip)',
    dev_sn_reg      = 'RegisterImage (any picture, then use it as an icon)',
    dev_sn_local    = 'AddLocalBlip (this player only, never stored)',
    dev_sn_evc      = 'Zone events (client)',
    dev_sn_evs      = 'Zone events (server)',
    dev_srv_t       = 'Server exports',
    dev_cli_t       = 'Client exports',
    dev_ev_t        = 'Events',
    dev_export_t    = 'Export all blips (JSON)',
    dev_export_btn  = 'Copy JSON',
    dev_import_t    = 'Import blips (JSON)',
    dev_import_ph   = 'Paste a JSON export here…',
    dev_import_btn  = 'Import',

    ----------------------------------------------------------------------------
    -- Studio toasts / modals
    ----------------------------------------------------------------------------
    t_saved         = 'Blip saved.',
    t_created       = 'Blip created.',
    t_deleted       = 'Blip deleted.',
    t_img_saved     = 'Image saved.',
    t_img_deleted   = 'Image deleted.',
    t_img_type      = 'That file is not an image.',
    t_img_big       = 'Image is too heavy even after downsizing (max %d KB).',
    t_need_name     = 'Give the blip a name first.',
    t_need_icon     = 'Choose an icon first.',
    t_need_image    = 'Choose or upload an image first.',
    t_need_badge    = 'Type something for the badge first.',
    t_bad_import    = 'That is not a valid blip export.',
    t_import_ok     = '%d blips sent to the server.',
    t_pick_wait     = 'Waiting for the map…',
    t_no_jobs       = 'Add at least one job, or switch visibility back to Everyone.',

    t_img_replaced  = 'Picture replaced. Every blip using it was updated.',
    t_img_busy      = 'One at a time. Try that again in a moment.',
    t_img_limit     = 'The library is full (max %d).',
    t_img_fail      = 'That image could not be saved.',
    t_img_timeout   = 'The server did not answer. The image was not saved.',
    t_img_progress  = 'Uploading pictures… %s',
    t_img_batch_ok  = '%d pictures saved.',
    t_img_batch_part = '%d of %d pictures saved.',
    t_img_room      = 'Only %d more fit in the library. The rest were skipped.',
    t_no_perm       = 'You are not allowed to edit blips.',
    act_replace     = 'Replace picture',
    act_replace_used = 'Replace picture (updates %d blips)',
    modal_del_t     = 'Delete this blip?',
    modal_del_d     = 'This removes it for every player. There is no undo.',
    modal_ok        = 'Delete',
    modal_cancel    = 'Cancel',
}
