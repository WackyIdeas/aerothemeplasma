cmake_minimum_required(VERSION 3.16)

project(io.gitgud.wackyideas.seventasks)
 
find_package(ECM 1.4.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
set(CMAKE_AUTOMOC ON)
set(QT_MAJOR_VERSION 6)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(FeatureSummary)
find_package(KF6WindowSystem)
find_package(KF6Svg)
find_package(KF6Config)
find_package(Plasma)
find_package(PlasmaQuick)


find_package(KF6 REQUIRED COMPONENTS
    I18n
)

find_package(Qt6 CONFIG REQUIRED COMPONENTS
    Quick
    Core
)

find_package(KF6CoreAddons)

add_subdirectory(src)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
