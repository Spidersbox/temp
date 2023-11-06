
#include <openssl/ec.h> // for EC_KEY definition

//#include "db.h"
//#include "walletdb.h"
//#include "bitcoinrpc.h"
//#include "net.h"
#include "init.h"
//#include "util.h"
//#include "ui_interface.h"
//#include "checkpoints.h"
#include "version.h"
#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>
#include <boost/filesystem/convenience.hpp>
#include <boost/interprocess/sync/file_lock.hpp>
#include <boost/algorithm/string/predicate.hpp>
#include <openssl/crypto.h>


//#ifndef WIN32 && __APPLE__
//#if (!defined(_WIN32)) && (!defined(WIN32)) && (!defined(__APPLE__))
//#include <signal.h>
//#include <execinfo.h>
//#include <ucontext.h>
//#endif

using namespace std;
using namespace boost;


/////////////////////////////////////////////////////////////////////////////
//
// Start
//

int main(int argc, char* argv[])
{
    bool fRet = false;

    fRet = AppInit2();


}


/** Initialize bitcoin.
 *  @pre Parameters should be parsed and config file should be read.
 */
bool AppInit2()
{
//#ifndef WIN32



    // ********************************************************* Step 1: setup
#ifdef _MSC_VER
    // Turn off Microsoft heap dump noise
    _CrtSetReportMode(_CRT_WARN, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_WARN, CreateFileA("NUL", GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, 0));
#endif
#if _MSC_VER >= 1400
    // Disable confusing "helpful" text message on abort, Ctrl-C
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
#endif
#ifdef WIN32
    // Enable Data Execution Prevention (DEP)
    // Minimum supported OS versions: WinXP SP3, WinVista >= SP1, Win Server 2008
    // A failure is non-critical and needs no further attention!
#ifndef PROCESS_DEP_ENABLE
// We define this here, because GCCs winbase.h limits this to _WIN32_WINNT >= 0x0601 (Windows 7),
// which is not correct. Can be removed, when GCCs winbase.h is fixed!
#define PROCESS_DEP_ENABLE 0x00000001
#endif
    typedef BOOL (WINAPI *PSETPROCDEPPOL)(DWORD);
    PSETPROCDEPPOL setProcDEPPol = (PSETPROCDEPPOL)GetProcAddress(GetModuleHandleA("Kernel32.dll"), "SetProcessDEPPolicy");
    if (setProcDEPPol != NULL) setProcDEPPol(PROCESS_DEP_ENABLE);
#endif
//#ifndef WIN32



    // ********************************************************* Step 4: application initialization: dir lock, daemonize, pidfile, debug log

    std::string strDataDir = GetDataDir().string();

    // Make sure only a single Bitcoin process is using the data directory.
    boost::filesystem::path pathLockFile = GetDataDir() / ".lock";
    FILE* file = fopen(pathLockFile.string().c_str(), "a"); // empty lock file; created if it doesn't exist.
    if (file) fclose(file);
    static boost::interprocess::file_lock lock(pathLockFile.string().c_str());
    if (!lock.try_lock())
        return (printf("Cannot obtain a lock on data directory %s.  HamstersDB is probably already running."), strDataDir.c_str());






    printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
    printf("HamstersDB version %s \n",CLIENT_DATE.c_str());
    printf("Using OpenSSL version %s\n", SSLeay_version(SSLEAY_VERSION));
    printf("Default data directory %s\n", GetDefaultDataDir().string().c_str());
    printf("Used data directory %s\n", strDataDir.c_str());
    //check for themes directory, and create if missing
    if (!boost::filesystem::exists(GetDataDir() / "themes"))
    {
      boost::filesystem::path temppath;
      temppath = GetDataDir() / "themes";
      boost::filesystem::create_directory(temppath);
      printf("created themes directory %s\n", temppath.string().c_str());
      temppath = GetDataDir() / "themes/images";
      boost::filesystem::create_directory(temppath);
      printf("created themes directory %s\n", temppath.string().c_str());
    }




    printf("Done loading\n");

   return true;
}

const boost::filesystem::path &GetDataDir()
{
    namespace fs = boost::filesystem;


    static fs::path pathCached;
    fs::path &path = pathCached;

/*
    // This can be called during exceptions by printf, so we cache the
    // value so we don't have to do memory allocations after that.
    if (cachedPath[fNetSpecific])
        return path;

    LOCK(csPathCached);

    if (mapArgs.count("-datadir")) {
        path = fs::system_complete(mapArgs["-datadir"]);
        if (!fs::is_directory(path)) {
            path = "";
            return path;
        }
    } else {

*/

// continue as normal
    path = GetDefaultDataDir();
 printf("path = %s\n", path.string().c_str());


    fs::create_directory(path);
    return path;
}

boost::filesystem::path GetDefaultDataDir()
{
  namespace fs = boost::filesystem;
  // Windows < Vista: C:\Documents and Settings\Username\Application Data\HamstersDB
  // Windows >= Vista: C:\Users\Username\AppData\Roaming\HamstersDB
  // Mac: ~/Library/Application Support/HamstersDB
  // Unix: ~/.HamstersDB
#ifdef WIN32
  // Windows
  return GetSpecialFolderPath(CSIDL_APPDATA) / appName;
#else
  fs::path pathRet;
  char* pszHome = getenv("HOME");
  if (pszHome == NULL || strlen(pszHome) == 0)
    pathRet = fs::path("/");
  else
    pathRet = fs::path(pszHome);
#ifdef MAC_OSX
  // Mac
  pathRet /= "Library/Application Support";
  fs::create_directory(pathRet);
  return pathRet / appName;
#else
  // Unix
  string apppath = "." + appName;
 printf("getdefaultdatadir returning %s/\/%s\n", pathRet,apppath);
  return pathRet / apppath;
#endif
#endif
}

