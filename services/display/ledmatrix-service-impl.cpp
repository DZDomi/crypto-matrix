//
// Created by dominik on 21.12.20.
//

#include <fstream>
#include "ledmatrix-service-impl.h"

LedMatrixServiceImpl::LedMatrixServiceImpl(LedMatrix *ledMatrix, string savePath) {
    this->matrix = ledMatrix;
    this->pathToSave = savePath;

    this->currentStyle = models::Design_Style_MULTI_ASSET;
    fstream stateFile(this->pathToSave, ios::in | ios::binary);
    if (!stateFile) {
        log("LedMatrixServiceImpl", "No old state found");
        return;
    }
    models::Design design;
    if (!design.ParseFromIstream(&stateFile)) {
        log("LedMatrixServiceImpl", "Unable to load old design from state");
        return;
    }
    this->currentStyle = design.style();
    log("LedMatrixServiceImpl", "Loaded old design from state");
}

grpc::Status LedMatrixServiceImpl::ReceiveOHLCUpdate(grpc::ServerContext* context, const ledmatrix::ReceiveOHLCUpdateRequest* request, ledmatrix::ReceiveOHLCUpdateResponse* response) {
    if (this->currentStyle == models::Design_Style_MULTI_ASSET) {
        log("LedMatrixServiceImpl", "Received ohlc update, but not showing single asset chart");
        return grpc::Status::OK;
    } else if (this->currentStyle == models::Design_Style_SINGLE_ASSET) {
        if (!request->market().active()) {
            log("LedMatrixServiceImpl", "Received ohlc update with inactive market, not showing");
            return grpc::Status::OK;
        }
    }
    this->matrix->printChart(request->interval());
    return grpc::Status::OK;
}

grpc::Status LedMatrixServiceImpl::ReceiveTrade(grpc::ServerContext* context, const ledmatrix::ReceiveTradeRequest* request, ledmatrix::ReceiveTradeResponse* response) {

    for (const models::Trade& trade : request->trades()) {
        log("LedMatrixServiceImpl", "Symbol: " + trade.market().pair().symbol() + ", Side: " + to_string(trade.side()) + ", Price: " + trade.price() + ", Row: " + to_string(trade.market().row()));

        rgb_matrix::Color color;
        if (trade.side() == models::Side::Buy) {
            color = rgb_matrix::Color(0, 255, 0);
        } else {
            color = rgb_matrix::Color(255, 0, 0);
        }

        string baseSymbol = trade.market().pair().base().symbol();
        toUpperCase(baseSymbol);

        string quoteSymbol = trade.market().pair().quote().symbol();
        toUpperCase(quoteSymbol);

        // -2 cause of the currency symbol at the end and a space
        string formattedPrice = formatPrice(trade.price(), this->matrix->getMaxCharacters() - baseSymbol.length() - 2);

        string line = baseSymbol;
        for (int i = baseSymbol.length() + formattedPrice.length() + 1; i < this->matrix->getMaxCharacters(); i++) {
            line += " ";
        }

        if (quoteSymbol == "EUR") {
            formattedPrice += "€";
        } else if (quoteSymbol == "USD" || quoteSymbol == "USDT" || quoteSymbol == "USDC" || quoteSymbol == "FDUSD") {
            formattedPrice += "$";
        } else {
            formattedPrice += quoteSymbol[0];
        }

        line += formattedPrice;

        if (this->currentStyle == models::Design_Style_SINGLE_ASSET) {
            if (!trade.market().active()) {
                log("LedMatrixServiceImpl", "Received trade update for inactive market: " + trade.market().pair().symbol() + " in single asset mode");
            } else {
                this->matrix->printText(LedMatrix::MAX_LINES, line, color);
            }
        } else if (this->currentStyle == models::Design_Style_MULTI_ASSET) {
            this->matrix->printText(trade.market().row(), line, color);
        }
    }
    return grpc::Status::OK;
}

grpc::Status LedMatrixServiceImpl::SetBrightness(grpc::ServerContext* context, const ledmatrix::SetBrightnessRequest* request, ledmatrix::SetBrightnessResponse* response) {
    int brightness = request->brightness();
    this->matrix->setBrightness(brightness);
    response->set_success(true);
    return grpc::Status::OK;
}

grpc::Status LedMatrixServiceImpl::SetDesign(grpc::ServerContext* context, const ledmatrix::SetDesignRequest* request, ledmatrix::SetDesignResponse* response) {
    fstream stateFile(this->pathToSave, ios::out | ios::trunc | ios::binary);
    if (request->design().SerializeToOstream(&stateFile)) {
        this->currentStyle = request->design().style();
        response->set_success(true);
    } else {
        response->set_success(false);
    }
    return grpc::Status::OK;
}

grpc::Status LedMatrixServiceImpl::EmptyRow(grpc::ServerContext *context, const ledmatrix::EmptyRowRequest *request, ledmatrix::EmptyRowResponse *response) {
    this->matrix->emptyRow(request->row());
    response->set_success(true);
    return grpc::Status::OK;
}

grpc::Status LedMatrixServiceImpl::Clear(grpc::ServerContext* context, const ledmatrix::ClearRequest* request, ledmatrix::ClearResponse* response) {
    this->matrix->clear();
    response->set_success(true);
    return grpc::Status::OK;
}