#include <cstdlib>
#include <iostream>

#include "util.h"
#include "ledmatrix.h"
#include "server.h"
#include "ledmatrix.pb.h"

using namespace std;
using namespace util;
using namespace ledmatrix;

string getEnvAsString(const char *key, const string &fallback) {
    const char *value = getenv(key);
    if (value == nullptr || value[0] == '\0') {
        return fallback;
    }
    return value;
}

int main(int argc, char *argv[]) {

    GOOGLE_PROTOBUF_VERIFY_VERSION;

    const string socketPath = getEnvAsString("GRPC_PATH", "unix:///run/crypto-matrix/display.sock");
    const string stateSavePath = getEnvAsString("STATE_PATH", "display.state");

    log("main", "Getting instance of led matrix");
    LedMatrix *ledMatrix = LedMatrix::getInstance();

    log("main", "Getting server object");
    auto *server = new Server(socketPath, ledMatrix, stateSavePath);
    log("main", "Server listening on: " + socketPath);
    server->acceptConnections();

    delete server;
    google::protobuf::ShutdownProtobufLibrary();

    return EXIT_SUCCESS;
}