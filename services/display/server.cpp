//
// Created by dominik on 20.12.20.
//

#include "server.h"
#include "ledmatrix-service-impl.h"

void Server::acceptConnections() {
    this->server->Wait();
}

Server::Server(const string& path, LedMatrix *matrix, string stateSavePath) {
    this->service = new LedMatrixServiceImpl(matrix, stateSavePath);
    grpc::ServerBuilder builder;
    builder.AddListeningPort(path, grpc::InsecureServerCredentials());
    builder.RegisterService(this->service);
    this->server = builder.BuildAndStart();
}