#import "Engine.hpp"
#include <algorithm>
#include <cmath>
#include <functional>
#include <queue>
#include <numeric>
#include <climits>

namespace Engine {

// ── Internal types ──────────────────────────────────────────

struct PlaceResult {
    Board         board;
    int           cleared;
    bool          ok;
    std::vector<int> cRows;
    std::vector<int> cCols;
};

struct Candidate {
    int   lc;
    int   r;
    int   c;
    Board nb;
};

// ── Place a block onto the board ────────────────────────────

static PlaceResult place(const Board &bd, const Block &bk, int pr, int pc) {
    PlaceResult res;
    res.ok      = false;
    res.cleared = 0;

    if (pr < 0 || pc < 0 || pr + bk.rows > 8 || pc + bk.cols > 8)
        return res;

    for (int r = 0; r < bk.rows; r++)
        for (int c = 0; c < bk.cols; c++)
            if (bk.mat[r][c] && bd[pr + r][pc + c])
                return res;

    res.board = bd;
    for (int r = 0; r < bk.rows; r++)
        for (int c = 0; c < bk.cols; c++)
            if (bk.mat[r][c])
                res.board[pr + r][pc + c] = 1;

    // Detect full rows
    for (int r = 0; r < 8; r++) {
        bool full = true;
        for (int c = 0; c < 8; c++)
            if (!res.board[r][c]) { full = false; break; }
        if (full) res.cRows.push_back(r);
    }
    // Detect full cols
    for (int c = 0; c < 8; c++) {
        bool full = true;
        for (int r = 0; r < 8; r++)
            if (!res.board[r][c]) { full = false; break; }
        if (full) res.cCols.push_back(c);
    }
    // Clear full rows / cols
    for (int cr : res.cRows)
        for (int c = 0; c < 8; c++)
            res.board[cr][c] = 0;
    for (int cc : res.cCols)
        for (int r = 0; r < 8; r++)
            res.board[r][cc] = 0;

    res.cleared = (int)res.cRows.size() + (int)res.cCols.size();
    res.ok      = true;
    return res;
}

// ── Count disconnected empty regions (fragmentation penalty) ─

static int emptyRegions(const Board &bd) {
    bool vis[8][8] = {};
    int  regions   = 0;
    const int dx[] = { 0,  0, 1, -1};
    const int dy[] = { 1, -1, 0,  0};

    for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
            if (bd[r][c] || vis[r][c]) continue;
            regions++;
            std::queue<std::pair<int,int>> q;
            q.push({r, c});
            vis[r][c] = true;
            while (!q.empty()) {
                auto [cr, cc] = q.front(); q.pop();
                for (int d = 0; d < 4; d++) {
                    int nr = cr + dx[d], nc = cc + dy[d];
                    if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8
                        && !bd[nr][nc] && !vis[nr][nc]) {
                        vis[nr][nc] = true;
                        q.push({nr, nc});
                    }
                }
            }
        }
    }
    return regions;
}

// ── Heuristic evaluation ─────────────────────────────────────

static double evaluate(const Board          &bd,
                       int                   totalLines,
                       const std::vector<int> &clearsPerStep) {
    double score = 0.0;

    // Line-clear reward (super-linear)
    if (totalLines > 0)
        score += 10000.0 * std::pow((double)totalLines, 1.5);

    // Combo bonus
    int combo = 0;
    for (int lc : clearsPerStep) {
        if (lc > 0) { combo++; score += 3000.0 * combo; }
        else          combo = 0;
    }

    // Column heights, holes, bumpiness
    int    holes    = 0;
    double wh       = 0.0;
    int    heights[8] = {};

    for (int c = 0; c < 8; c++) {
        int top = -1;
        for (int r = 0; r < 8; r++)
            if (bd[r][c]) { top = r; break; }

        if (top >= 0) {
            heights[c] = 8 - top;
            for (int r = top; r < 8; r++)
                if (!bd[r][c]) holes++;
            wh += (double)heights[c] * heights[c];
        }
    }

    score -= holes * 800.0;
    score -= wh    *  15.0;

    int bump = 0;
    for (int i = 0; i < 7; i++)
        bump += std::abs(heights[i] - heights[i+1]);
    score -= bump * 60.0;

    // Near-full row / col bonus
    for (int r = 0; r < 8; r++) {
        int f = 0;
        for (int c = 0; c < 8; c++) f += bd[r][c];
        if      (f == 7) score += 2000;
        else if (f == 6) score +=  800;
        else if (f == 5) score +=  200;
    }
    for (int c = 0; c < 8; c++) {
        int f = 0;
        for (int r = 0; r < 8; r++) f += bd[r][c];
        if      (f == 7) score += 2000;
        else if (f == 6) score +=  800;
        else if (f == 5) score +=  200;
    }

    // Prefer blocks to sit low (gravity bias)
    double rowSum = 0.0;
    int    cnt    = 0;
    for (int r = 0; r < 8; r++)
        for (int c = 0; c < 8; c++)
            if (bd[r][c]) { rowSum += r; cnt++; }
    if (cnt > 0)
        score += (rowSum / cnt) * 30.0;

    // Fragmentation penalty
    int reg = emptyRegions(bd);
    if (reg > 1)
        score -= (reg - 1) * 300.0;

    return score;
}

// ── Recursive DFS solver ─────────────────────────────────────

static void dfs(const Board         &bd,
                std::vector<Block>  &rem,
                std::vector<Move>   &path,
                std::vector<int>    &clears,
                double               alpha,
                Solution            &best) {

    if (rem.empty()) {
        int total = 0;
        for (int x : clears) total += x;
        double s = evaluate(bd, total, clears);
        if (s > best.score) {
            best.score = s;
            best.path  = path;
        }
        return;
    }

    int n = (int)rem.size();
    for (int i = 0; i < n; i++) {
        Block bk = rem[i];

        std::vector<Block> rest;
        rest.reserve(n - 1);
        for (int j = 0; j < n; j++)
            if (j != i) rest.push_back(rem[j]);

        // Collect valid placements
        std::vector<Candidate> cands;
        for (int r = 0; r <= 8 - bk.rows; r++) {
            for (int c = 0; c <= 8 - bk.cols; c++) {
                PlaceResult res = place(bd, bk, r, c);
                if (!res.ok) continue;
                Candidate cd;
                cd.lc = res.cleared;
                cd.r  = r;
                cd.c  = c;
                cd.nb = res.board;
                cands.push_back(cd);
            }
        }
        if (cands.empty()) continue;

        // Rank: prefer more clears, then lower rows (gravity)
        std::sort(cands.begin(), cands.end(),
            [](const Candidate &a, const Candidate &b) {
                return a.lc != b.lc ? a.lc > b.lc : a.r > b.r;
            });

        for (auto &cd : cands) {
            // Optimistic pruning
            if (!best.path.empty()) {
                int curTotal = 0;
                for (int x : clears) curTotal += x;
                curTotal += cd.lc;
                int    remaining = (int)rest.size();
                double optimistic = 10000.0 * std::pow(curTotal + remaining * 2.0, 1.5)
                                  + 3000.0  * std::pow((double)(clears.size() + 1 + remaining), 2.0);
                if (optimistic < best.score * 0.3) continue;
            }

            Move mv { bk.id, cd.r, cd.c, cd.lc };
            path.push_back(mv);
            clears.push_back(cd.lc);

            dfs(cd.nb, rest, path, clears,
                std::max(alpha, best.score), best);

            path.pop_back();
            clears.pop_back();
        }
    }
}

// ── Public API ───────────────────────────────────────────────

Solution solve(const Board &bd, std::vector<Block> &blocks) {
    Solution best;
    best.score = -1e18;
    std::vector<Move> path;
    std::vector<int>  clears;
    dfs(bd, blocks, path, clears, -1e18, best);
    return best;
}

} // namespace Engine