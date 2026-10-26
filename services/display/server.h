//
// Created by dominik on 20.12.20.
//

#ifndef DISPLAY_SERVER_H
#define DISPLAY_SERVER_H


#include <grpc/grpc.h>
#include <grpcpp/server.h>
#include <grpcpp/server_builder.h>
#include <grpcpp/server_context.h>
#include <grpcpp/security/server_credentials.h>

#include "ledmatrix.h"
#include "ledmatrix-service-impl.h"

class Server {
    public:
        Server(const string& path, LedMatrix *matrix, string stateSavePath);
        void acceptConnections();

    private:
        unique_ptr<grpc::Server> server = nullptr;
        LedMatrixServiceImpl *service = nullptr;
};

#endif //DISPLAY_SERVER_H
