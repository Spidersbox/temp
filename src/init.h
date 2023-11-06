#ifndef INIT_H
#define INIT_H
#include <sys/time.h>
#include <boost/filesystem.hpp>
#include <boost/filesystem/path.hpp>

void StartShutdown();
void Shutdown(void* parg);
bool AppInit2();
std::string appName = "HamstersDB-Update";

const boost::filesystem::path &GetDataDir();
boost::filesystem::path GetDefaultDataDir();



#endif
