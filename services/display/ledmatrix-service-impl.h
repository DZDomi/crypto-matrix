//
// Created by dominik on 21.12.20.
//

#ifndef DISPLAY_LEDMATRIX_SERVICE_IMPL_H
#define DISPLAY_LEDMATRIX_SERVICE_IMPL_H

#include <grpc/grpc.h>
#include <grpcpp/server.h>
#include <grpcpp/server_builder.h>
#include <grpcpp/server_context.h>
#include <grpcpp/security/server_credentials.h>

#include "ledmatrix.grpc.pb.h"

#include "ledmatrix.h"

class LedMatrixServiceImpl final : public ledmatrix::LedMatrixService::Service {
public:
    explicit LedMatrixServiceImpl(LedMatrix *ledMatrix, string savePath);
    grpc::Status ReceiveOHLCUpdate(grpc::ServerContext* context, const ledmatrix::ReceiveOHLCUpdateRequest* request, ledmatrix::ReceiveOHLCUpdateResponse* response) override;
    grpc::Status ReceiveTrade(grpc::ServerContext* context, const ledmatrix::ReceiveTradeRequest* request, ledmatrix::ReceiveTradeResponse* response) override;
    grpc::Status SetBrightness(grpc::ServerContext* context, const ledmatrix::SetBrightnessRequest* request, ledmatrix::SetBrightnessResponse* response) override;
    grpc::Status SetDesign(grpc::ServerContext* context, const ledmatrix::SetDesignRequest* request, ledmatrix::SetDesignResponse* response) override;
    grpc::Status EmptyRow(grpc::ServerContext *context, const ledmatrix::EmptyRowRequest *request, ledmatrix::EmptyRowResponse *response) override;
    grpc::Status Clear(grpc::ServerContext* context, const ledmatrix::ClearRequest* request, ledmatrix::ClearResponse* response) override;
private:
    LedMatrix *matrix = nullptr;
    string pathToSave;
    models::Design_Style currentStyle;
};


#endif //DISPLAY_LEDMATRIX_SERVICE_IMPL_H
