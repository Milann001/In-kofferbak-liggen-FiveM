Config = {}

-- General settings
Config.ProgressBarDuration = 10000 -- 10 seconds in milliseconds
Config.InteractionDistance = 2.0 -- Distance to interact with trunk
Config.CheckInterval = 500 -- Check interval for updates in milliseconds

-- Vehicle restrictions - vehicles that cannot have trunk access
Config.BlacklistedVehicles = {
    -- Motorcycles and bikes
    'akuma',
    'bagger',
    'bati',
    'bati2',
    'bf400',
    'carbonrs',
    'chimera',
    'cliffhanger',
    'daemon',
    'daemon2',
    'defiler',
    'diablous',
    'diablous2',
    'double',
    'enduro',
    'esskey',
    'faggio',
    'faggio2',
    'faggio3',
    'fcr',
    'fcr2',
    'gargoyle',
    'hakuchou',
    'hakuchou2',
    'hexer',
    'innovation',
    'lectro',
    'manchez',
    'nemesis',
    'nightblade',
    'pcj',
    'ruffian',
    'sanchez',
    'sanchez2',
    'sanctus',
    'shotaro',
    'sovereign',
    'thrust',
    'vader',
    'vindicator',
    'vortex',
    'wolfsbane',
    'zombiea',
    'zombieb',
    
    -- Small vehicles without proper trunks
    'bmx',
    'cruiser',
    'fixter',
    'scorcher',
    'tribike',
    'tribike2',
    'tribike3',
    
    -- Boats
    'dinghy',
    'dinghy2',
    'dinghy3',
    'dinghy4',
    'jetmax',
    'marquis',
    'seashark',
    'seashark2',
    'seashark3',
    'speeder',
    'speeder2',
    'squalo',
    'submersible',
    'submersible2',
    'suntrap',
    'toro',
    'toro2',
    'tropic',
    'tropic2',
    'tug',
    
    -- Aircraft
    'buzzard',
    'buzzard2',
    'cargobob',
    'cargobob2',
    'cargobob3',
    'cargobob4',
    'frogger',
    'frogger2',
    'maverick',
    'polmav',
    'savage',
    'skylift',
    'supervolito',
    'supervolito2',
    'swift',
    'swift2',
    'valkyrie',
    'valkyrie2',
    'volatus',
    
    -- Add more vehicle models as needed
}

-- Animation settings
Config.EnterAnimation = {
    dict = 'missfinale_c2ig_11',
    clip = 'pushcar_offcliff_f'
}

-- Text settings
Config.Text = {
    EnterTrunk = 'In kofferbak gaan',
    ExitTrunk = 'E - Uit kofferbak',
    ProgressText = 'In koffer aan het kruipen...',
    VehicleMoving = 'Het voertuig moet stilstaan!',
    VehicleLocked = 'Het voertuig is vergrendeld!',
    VehicleBlacklisted = 'Je kan niet in de kofferbak van dit voertuig!',
    MustBeOutsideVehicle = 'Je moet eerst uit het voertuig stappen!'
}