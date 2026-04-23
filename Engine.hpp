#pragma once
#include <array>
#include <vector>
#include <cstring>

namespace Engine {

using Board = std::array<std::array<int8_t, 8>, 8>;

struct Block {
    int id;
    int rows;
    int cols;
    int8_t mat[5][5];

    Block() : id(0), rows(0), cols(0) {
        memset(mat, 0, sizeof(mat));
    }
};

struct Move {
    int blockId;
    int r;
    int c;
    int cleared;
};

struct Solution {
    double score;
    std::vector<Move> path;
};

Solution solve(const Board &board, std::vector<Block> &blocks);

} // namespace Engine