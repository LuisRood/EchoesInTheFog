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
            WalkSpeed = 10,
            RunSpeed = 22,
            Acceleration = 24,
            Deceleration = 28,
            BodyTurnSpeed = 0.12,
            CriticalHealthThreshold = 30,
            CriticalSpeedMultiplier = 0.5,
        },
        Stamina = {
            Max = 100,
            DrainRate = 10,
            RegenRate = 5,
            ExhaustionLimit = 30,
        },
        Flashlight = {
            FlickerChance = 0.02,
            Range = 45,
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
    },
}

return GameConstants
