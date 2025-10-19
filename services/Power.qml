pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import qs.settings

/**
 * Power service using Quickshell UPower API.
 * Provides access to power profiles and power management.
 */
Singleton {
    id: root

    // ===== Power Profile State =====
    
    readonly property int currentProfile: PowerProfiles.profile
    readonly property bool hasPerformanceProfile: PowerProfiles.hasPerformanceProfile
    readonly property int degradationReason: PowerProfiles.degradationReason
    readonly property var holds: PowerProfiles.holds
    
    // ===== Profile Names =====
    
    readonly property string currentProfileName: {
        switch (currentProfile) {
            case PowerProfile.Performance: return "High";
            case PowerProfile.Balanced: return "Balanced";
            case PowerProfile.PowerSaver: return "Eco";
            default: return "Unknown";
        }
    }
    
    // ===== Profile Icons =====
    
    readonly property string currentProfileIcon: {
        switch (currentProfile) {
            case PowerProfile.Performance: return Fonts.iconPowerFast;
            case PowerProfile.Balanced: return Fonts.iconPowerMedium;
            case PowerProfile.PowerSaver: return Fonts.iconPowerEco;
            default: return Fonts.iconPowerMedium;
        }
    }
    
    // ===== UPower Device State =====
    
    readonly property var displayDevice: UPower.displayDevice
    readonly property bool onBattery: UPower.onBattery
    readonly property bool hasBattery: displayDevice?.isLaptopBattery ?? false
    readonly property int batteryPercentage: hasBattery ? Math.round((displayDevice?.percentage ?? 0) * 100) : 0
    readonly property int batteryState: displayDevice?.state ?? 0
    readonly property bool isCharging: batteryState === 1 // UPowerDeviceState.Charging
    readonly property bool isDischarging: batteryState === 2 // UPowerDeviceState.Discharging
    readonly property bool isFull: batteryState === 4 // UPowerDeviceState.FullyCharged
    
    // ===== Control Functions =====
    
    /**
     * Set the power profile
     */
    function setProfile(profile: int): void {
        // Validate that we can set Performance mode
        if (profile === PowerProfile.Performance && !hasPerformanceProfile) {
            console.warn("Cannot set Performance profile: not available on this system");
            return;
        }
        
        // Validate the profile value
        if (profile !== PowerProfile.Performance && 
            profile !== PowerProfile.Balanced && 
            profile !== PowerProfile.PowerSaver) {
            console.warn("Invalid power profile:", profile);
            return;
        }
        
        PowerProfiles.profile = profile;
    }
    
    /**
     * Set Performance profile
     */
    function setPerformance(): void {
        setProfile(PowerProfile.Performance);
    }
    
    /**
     * Set Balanced profile
     */
    function setBalanced(): void {
        setProfile(PowerProfile.Balanced);
    }
    
    /**
     * Set Power Saver profile
     */
    function setPowerSaver(): void {
        setProfile(PowerProfile.PowerSaver);
    }
    
    /**
     * Cycle through available power profiles
     */
    function cycleProfile(): void {
        if (currentProfile === PowerProfile.PowerSaver) {
            setBalanced();
        } else if (currentProfile === PowerProfile.Balanced) {
            if (hasPerformanceProfile) {
                setPerformance();
            } else {
                setPowerSaver();
            }
        } else if (currentProfile === PowerProfile.Performance) {
            setPowerSaver();
        }
    }
    
    /**
     * Get degradation reason as human-readable string
     */
    function getDegradationReasonString(): string {
        switch (degradationReason) {
            case PerformanceDegradationReason.None: return "";
            case PerformanceDegradationReason.HighTemperature: return "High Temperature";
            case PerformanceDegradationReason.LapDetected: return "Lap Detected";
            default: return "Unknown Reason";
        }
    }
    
    /**
     * Check if a profile is currently active
     */
    function isProfileActive(profile: int): bool {
        return currentProfile === profile;
    }
    
}
