local GameConstants = {
    Door = {
        TweenDuration = 2.5,
        RotationDegrees = 90,
        BlockedWaitSeconds = 2,
    },
    Player = {
        HealthRestore = 50,
    },
    Endgame = {
        CinematicTimeSeconds = 6,
    },
    Client = {
        Camera = {
            Sensitivity = 0.003,
            Lag = 0.15,
            MaxPitchDegrees = 60,
            MinPitchDegrees = -60,
            Offset = Vector3.new(0, 2, 6),
        },
        Movement = {
            WalkSpeed = 15,
            RunSpeed = 25,
            Acceleration = 27,
            Deceleration = 29,
            BodyTurnSpeed = 0.12,
            CriticalHealthThreshold = 30,
            CriticalSpeedMultiplier = 0.5,
        },
        Stamina = {
            Max = 200,
            DrainRate = 10,
            RegenRate = 8,
            ExhaustionLimit = 30,
        },
        Flashlight = {
            FlickerChance = 0.02,
            Range = 50,
            Angle = 50,
            MaxBrightness = 2,
            FlickerDropMax = 1.5,
            RecoverRate = 10,
        },
        Radio = {
            MaxDistance = 60,
            LerpAlpha = 0.1,
        },
        EndgameUI = {
            FadeSeconds = 4,
            PostFadeSeconds = 2,
        },
        Sounds = {
            GunshotVolume = 0.8,
            GunshotSoundId = "rbxassetid://123448793380050", -- Sonido de balazo genérico de Roblox
            ReloadVolume = 0.5,
            ReloadSoundId = "rbxassetid://139798971373512", -- Sonido de recarga
        },
        Controls = {
            StickDeadzone = 0.12,
            KeyboardTurnRateDegPerSec = 170,
            GamepadTurnRateDegPerSec = 210,
            GamepadLookRateDegPerSec = 180,
            MobileLookAreaMinX = 0.45,
            MobileLookSensitivityMultiplier = 0.8,
            MobileButtons = {
                RunPosition = UDim2.new(0.83, 0, 0.64, 0),
                FlashlightPosition = UDim2.new(0.83, 0, 0.77, 0),
                InventoryPosition = UDim2.new(0.70, 0, 0.77, 0),
                ReloadPosition = UDim2.new(0.57, 0, 0.77, 0),
                FirePosition = UDim2.new(0.70, 0, 0.64, 0),
            },
        },
    },
    Weapons = {
        HitscanDistance = 180,
        FireCooldownSeconds = 0.12,
        MaxOriginOffsetFromHead = 20,
        ReloadDebounceSeconds = 0.2,
    },
    Server = {
        MovementValidation = {
            Enabled = true,
            MaxSpeed = 25,
            ToleranceFactor = 2.6,
            GraceDistance = 2,
            MaxStrikes = 3,
        },
    },
}

return GameConstants
