TEMPLATE = app
TARGET = HamstersDB
VERSION = 1.0.1.1
INCLUDEPATH += src src/json src/qt /usr/include/libdb4
DEFINES += QT_GUI BOOST_THREAD_USE_LIB BOOST_SPIRIT_THREADSAFE BOOST_ASIO_ENABLE_OLD_SERVICES
CONFIG += no_include_pwd
CONFIG += thread -w
QT += widgets
QT += network

OBJECTS_DIR = build
MOC_DIR = build
UI_DIR = build

# use: qmake "RELEASE=1"
contains(RELEASE, 1) {
    # Mac: compile for maximum compatibility (10.5, 32-bit)
    macx:QMAKE_CXXFLAGS += -mmacosx-version-min=10.5 -arch i386 -isysroot /Developer/SDKs/MacOSX10.5.sdk

    !windows:!macx {
        # Linux: static link
        LIBS += -Wl,-Bstatic
    }
}

!win32 {
# for extra security against potential buffer overflows: enable GCCs Stack Smashing Protection
QMAKE_CXXFLAGS *= -fstack-protector-all --param ssp-buffer-size=1
QMAKE_LFLAGS *= -rdynamic -fstack-protector-all --param ssp-buffer-size=1
  !macx {
  # -no-pie
  }
# We need to exclude this for Windows cross compile with MinGW 4.2.x, as it will result in a non-working executable!
# This can be enabled for Windows, when we switch to MinGW >= 4.4.x.
}
# for extra security on Windows: enable ASLR and DEP via GCC linker flags
win32:QMAKE_LFLAGS *= -Wl,--dynamicbase -Wl,--nxcompat


# use: qmake "USE_DBUS=1"
contains(USE_DBUS, 1) {
    message(Building with DBUS (Freedesktop notifications) support)
    DEFINES += USE_DBUS
    QT += dbus
}

# use: qmake "FIRST_CLASS_MESSAGING=1"
contains(FIRST_CLASS_MESSAGING, 1) {
    message(Building with first-class messaging)
    DEFINES += FIRST_CLASS_MESSAGING
}

contains(BITCOIN_NEED_QT_PLUGINS, 1) {
    DEFINES += BITCOIN_NEED_QT_PLUGINS
    QTPLUGIN += qcncodecs qjpcodecs qtwcodecs qkrcodecs qtaccessiblewidgets
}

# regenerate src/build.h
!windows|contains(USE_BUILD_INFO, 1) {
    genbuild.depends = FORCE
    genbuild.commands = cd $$PWD; /bin/sh share/genbuild.sh $$OUT_PWD/build/build.h
    genbuild.target = $$OUT_PWD/build/build.h
    PRE_TARGETDEPS += $$OUT_PWD/build/build.h
    QMAKE_EXTRA_TARGETS += genbuild
    DEFINES += HAVE_BUILD_INFO
}

#QMAKE_CXXFLAGS += -msse2 -w
#QMAKE_CFLAGS += -msse2
# If we have an arm device, we can't use sse2, so define as thumb
# Because of scrypt_mine.cpp, we also have to add a compile
#     flag that states we *really* don't have SSE
# Otherwise, assume sse2 exists
QMAKE_XCPUARCH = $$QMAKE_HOST.arch
equals(QMAKE_XCPUARCH, armv7l) {
    message(Building without SSE2 support)
	QMAKE_CXXFLAGS += -DNOSSE
    QMAKE_CFLAGS += -DNOSSE
}
else:equals(QMAKE_XCPUARCH, armv6l) {
    message(Building without SSE2 support)
	QMAKE_CXXFLAGS += -DNOSSE
    QMAKE_CFLAGS += -DNOSSE
}
else {
    message(Building with SSE2 support)
    QMAKE_CXXFLAGS += -msse2 -w
    QMAKE_CFLAGS += -msse2
}
#endif

QMAKE_CXXFLAGS_WARN_ON = -fdiagnostics-show-option -Wall -Wextra -Wformat -Wformat-security -Wno-unused-parameter -Wstack-protector

# Input
DEPENDPATH += src src/json src/qt
HEADERS += src/init.h \
           src/version.h \
           src/clientversion.h \
           src/main.h

SOURCES += src/version.cpp \
           src/init.cpp


RESOURCES += \
    src/qt/bitcoin.qrc


CODECFORTR = UTF-8

# for lrelease/lupdate
# also add new translations to src/qt/bitcoin.qrc under translations/
TRANSLATIONS = $$files(src/qt/locale/bitcoin_*.ts)

isEmpty(QMAKE_LRELEASE) {
    win32:QMAKE_LRELEASE = $$[QT_INSTALL_BINS]\\lrelease.exe
    else:QMAKE_LRELEASE = $$[QT_INSTALL_BINS]/lrelease
}
isEmpty(QM_DIR):QM_DIR = $$PWD/src/qt/locale
# automatically build translations, so they can be included in resource file
TSQM.name = lrelease ${QMAKE_FILE_IN}
TSQM.input = TRANSLATIONS
TSQM.output = $$QM_DIR/${QMAKE_FILE_BASE}.qm
TSQM.commands = $$QMAKE_LRELEASE ${QMAKE_FILE_IN} -qm ${QMAKE_FILE_OUT}
TSQM.CONFIG = no_link
QMAKE_EXTRA_COMPILERS += TSQM

# "Other files" to show in Qt Creator
OTHER_FILES += \
    contrib/gitian-descriptors/* doc/*.rst doc/*.txt doc/README README.md res/bitcoin-qt.rc \
    share/setup.nsi

# platform specific defaults, if not overridden on command line
isEmpty(BOOST_LIB_SUFFIX) {
    macx:BOOST_LIB_SUFFIX = -mt
    windows:BOOST_LIB_SUFFIX = -mgw10-mt-s-x64-1_73
}

isEmpty(BOOST_THREAD_LIB_SUFFIX) {
    BOOST_THREAD_LIB_SUFFIX = $$BOOST_LIB_SUFFIX
}

isEmpty(BDB_LIB_PATH) {
    macx:BDB_LIB_PATH = /opt/local/lib/db48
}

isEmpty(BDB_LIB_SUFFIX) {
    macx:BDB_LIB_SUFFIX = -4.8
}

isEmpty(BDB_INCLUDE_PATH) {
    macx:BDB_INCLUDE_PATH = /opt/local/include/db48
}

isEmpty(BOOST_LIB_PATH) {
    macx:BOOST_LIB_PATH = /opt/local/lib
}

isEmpty(BOOST_INCLUDE_PATH) {
    macx:BOOST_INCLUDE_PATH = /opt/local/include
}

windows:DEFINES += WIN32
windows:RC_FILE = src/qt/res/bitcoin-qt.rc

windows:!contains(MINGW_THREAD_BUGFIX, 0) {
    # At least qmake's win32-g++-cross profile is missing the -lmingwthrd
    # thread-safety flag. GCC has -mthreads to enable this, but it doesn't
    # work with static linking. -lmingwthrd must come BEFORE -lmingw, so
    # it is prepended to QMAKE_LIBS_QT_ENTRY.
    # It can be turned off with MINGW_THREAD_BUGFIX=0, just in case it causes
    # any problems on some untested qmake profile now or in the future.
    DEFINES += _MT
    QMAKE_LIBS_QT_ENTRY = -lmingwthrd $$QMAKE_LIBS_QT_ENTRY
}

!windows:!mac {
    DEFINES += LINUX
    LIBS += -lrt
}

macx:HEADERS += src/qt/macdockiconhandler.h
macx:OBJECTIVE_SOURCES += src/qt/macdockiconhandler.mm
macx:LIBS += -framework Foundation -framework ApplicationServices -framework AppKit
macx:DEFINES += MAC_OSX MSG_NOSIGNAL=0
macx:ICON = src/qt/res/icons/spb.icns
macx:TARGET = "HamstersDB-qt"
macx:QMAKE_CFLAGS_THREAD += -pthread
macx:QMAKE_LFLAGS_THREAD += -pthread
macx:QMAKE_CXXFLAGS_THREAD += -pthread

# Set libraries and includes at end, to use platform-defined defaults if not overridden
INCLUDEPATH += $$BOOST_INCLUDE_PATH $$BDB_INCLUDE_PATH $$OPENSSL_INCLUDE_PATH $$QRENCODE_INCLUDE_PATH
LIBS += $$join(BOOST_LIB_PATH,,-L,) $$join(BDB_LIB_PATH,,-L,) $$join(OPENSSL_LIB_PATH,,-L,) $$join(QRENCODE_LIB_PATH,,-L,)
LIBS += -lssl -lcrypto -ldb_cxx$$BDB_LIB_SUFFIX
# -lgdi32 has to happen after -lcrypto (see  #681)
windows:LIBS += -lws2_32 -lshlwapi -lmswsock -lole32 -loleaut32 -luuid -lgdi32
LIBS += -lboost_system$$BOOST_LIB_SUFFIX -lboost_filesystem$$BOOST_LIB_SUFFIX -lboost_program_options$$BOOST_LIB_SUFFIX -lboost_thread$$BOOST_THREAD_LIB_SUFFIX
windows:LIBS += -lboost_chrono$$BOOST_LIB_SUFFIX -static-libgcc -static-libstdc++ -Wl,-Bstatic -lstdc++ -lpthread -Wl,--stack,16777216


contains(RELEASE, 1) {
    !windows:!macx {
        # Linux: turn dynamic linking back on for c/c++ runtime libraries
        LIBS += -Wl,-Bdynamic
    }
}

system($$QMAKE_LRELEASE -silent $$_PRO_FILE_)

