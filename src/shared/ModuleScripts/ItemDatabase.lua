local ItemDatabase = {
    
    -- ==========================================
    -- CONSUMIBLES (Curación)
    -- ==========================================
    ["BebidaSalud"] = { 
        Tipo = "Consumible", 
        Curacion = 25, 
        MaxStack = 10, 
        Descripcion = "Una bebida nutritiva. Recupera un poco de salud." 
    },
    ["Botiquin"] = { 
        Tipo = "Consumible", 
        Curacion = 50, 
        MaxStack = 5, 
        Descripcion = "Caja de primeros auxilios. Cura heridas moderadas." 
    },
    ["Ampolleta"] = { 
        Tipo = "Consumible", 
        Curacion = 100, 
        MaxStack = 3, 
        Descripcion = "Medicina fuerte. Alivia el dolor por completo al instante." 
    },

    -- ==========================================
    -- ARMAS CUERPO A CUERPO (Melee)
    -- ==========================================
    ["CuchilloCocina"] = { 
        Tipo = "Melee", 
        Dano = 15, 
        Rango = 3, 
        MaxStack = 1, 
        Descripcion = "Cuchillo afilado. Rápido pero te obliga a acercarte mucho." 
    },
    ["TuboAcero"] = { 
        Tipo = "Melee", 
        Dano = 25, 
        Rango = 6, 
        MaxStack = 1, 
        Descripcion = "Un tubo de metal largo. Perfecto para mantener la distancia." 
    },
    ["MartilloEmergencia"] = { 
        Tipo = "Melee", 
        Dano = 45, 
        Rango = 4, 
        MaxStack = 1, 
        Descripcion = "Pesado y letal, pero deja la guardia abierta al fallar." 
    },

    -- ==========================================
    -- ARMAS DE FUEGO
    -- ==========================================
    ["Pistola"] = { 
        Tipo = "Fuego", 
        Dano = 20, 
        Capacidad = 15, 
        UsaMunicion = "BalasPistola", 
        ReloadTimeSeconds = 2,
        MaxStack = 1, 
        Descripcion = "Pistola estándar. Fiable a media distancia." 
    },
    ["Escopeta"] = { 
        Tipo = "Fuego", 
        Dano = 60, 
        Capacidad = 6, 
        UsaMunicion = "CartuchosEscopeta", 
        ReloadTimeSeconds = 2,
        MaxStack = 1, 
        Descripcion = "Devastadora de cerca, inútil de lejos." 
    },
    ["RifleCaza"] = { 
        Tipo = "Fuego", 
        Dano = 80, 
        Capacidad = 5, 
        UsaMunicion = "BalasRifle", 
        ReloadTimeSeconds = 3,
        MaxStack = 1, 
        Descripcion = "Precisión y daño extremo. Munición muy escasa." 
    },

    -- ==========================================
    -- MUNICIÓN
    -- ==========================================
    ["BalasPistola"] = { Tipo = "Municion", MaxStack = 50, PickupAmount = 15, Descripcion = "Balas calibre 9mm." },
    ["CartuchosEscopeta"] = { Tipo = "Municion", MaxStack = 30, Descripcion = "Cartuchos de perdigones." },
    ["BalasRifle"] = { Tipo = "Municion", MaxStack = 20, Descripcion = "Balas perforantes pesadas." }
}

return ItemDatabase