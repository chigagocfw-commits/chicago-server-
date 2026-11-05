-- police items
return {
    ['instant_camera'] = {
        label = 'Instant Camera',
        weight = 0,
        consume = 0,
        description = 'A simple camera designed to take photos at a crime scene',
        server = { export = "origen_police.instant_camera" },
        client = { image = 'polaroid.png' }
    },

    ['photo'] = {
        label = 'Photo',
        weight = 0,
        consume = 0,
        description = 'An image',
        server = { export = "origen_police.photo"},
        client = { image = 'photos.png' }
    },

    ['evidence_a'] = {
        label = 'Evidence of Bullet',
        weight = 0,
        consume = 0,
        description = 'Evidence obtained from a crime scene',
        client = { image = 'evidence_a.png' }
    },

    ['evidence_az'] = {
        label = 'Evidence',
        weight = 0,
        consume = 0,
        description = 'Evidence obtained from a crime scene',
        client = { image = 'evidence_az.png' }
    },

    ['evidence_b'] = {
        label = 'Vehicle Evidence',
        weight = 0,
        consume = 0,
        description = 'Evidence obtained from a crime scene',
        client = { image = 'evidence_b.png' }
    },

    ['evidence_n'] = {
        label = 'Impact Evidence',
        weight = 0,
        consume = 0,
        description = 'Evidence obtained from a crime scene',
        client = { image = 'evidence_n.png' }
    },

    ['evidence_ne'] = {
        label = 'Footprint Evidence',
        weight = 0,
        consume = 0,
        description = 'Evidence obtained from a crime scene',
        client = { image = 'evidence_ne.png' }
    },

    ['evidence_r'] = {
        label = 'Blood Evidence',
        weight = 0,
        consume = 0,
        description = 'Evidence obtained from a crime scene',
        client = { image = 'evidence_r.png' }
    },

    ['evidence_ro'] = {
        label = 'Evidence',
        weight = 0,
        consume = 0,
        description = 'Evidence obtained from a crime scene',
        client = { image = 'evidence_ro.png' }
    },

    ['evidence_v'] = {
        label = 'Drug Evidence',
        weight = 0,
        consume = 0,
        description = 'Evidence obtained from a crime scene',
        client = { image = 'evidence_v.png' }
    },

    ['report_evidence'] = {
        label = 'Evidence Report',
        weight = 0,
        consume = 0,
        description = 'Here there can be collected up to 4 pieces of evidence',
        server = { export = 'origen_police.report_evidence' },
        client = { image = 'report_evidence.png' }
    },

    ['k9'] = {
        label = 'K9 Whistle',
        weight = 0,
        consume = 0,
        description = 'Use the whistle to call the K9 unit',
        server = { export = "origen_police.k9" },
        client = { image = 'whistle.png' }
    },

    ['lspd_badge'] = {
        label = 'Police Badge',
        weight = 0,
        consume = 0,
        description = 'Your identification as a police officer, includes your rank and badge number',
        server = { export = "origen_police.lspd_badge" },
        client = { image = 'lspd_badge.png' }
    },

    ['bcsd_badge'] = {
        label = 'Sheriff Badge',
        weight = 0,
        consume = 0,
        description = "Your identification as a sheriff's agent, including your rank and badge number",
        server = { export = "origen_police.bcsd_badge" },
        client = { image = 'bcsd_badge.png' }
    },

    ['fib_badge'] = {
        label = "FIB Badge",
        weight = 200,
        server = { export = "origen_police.fib_badge"},
        consume = 0
    },

    ['police_cad'] = {
        label = 'Police Tablet',
        weight = 0,
        consume = 0,
        description = 'Your personal tablet with all the information of the San Andreas police',
        server = { export = "origen_police.police_cad" },
        client = { image = 'police_cad.png' }
    }
}