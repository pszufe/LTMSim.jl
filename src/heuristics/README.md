## Problem definition
#### The Target Set Selection (TSS) Problem on hypergraphs
- **Instance:** $H = (V, E)$, thresholds $t_V : V \rightarrow  N_0$ and $t_E : E \rightarrow N_0$.
- **Problem:** Find a seed set $S \subseteq V$ of minimum size such that $I_V[S]=V$.

## TSS Heuristics
Each heuristic may be followed by an optimization procedure.

#### Additive
- $StaticGreedy(H=(V,E),t_V, t_E)$
- $DynamicGreedy(H=(V,E),t_V, t_E)$
- $DynamicGreedy_{[H]_2}(H(V,E),t_V, t_E)$

#### Subtractive
- $SubTSSH(H=(V,E),t_V, t_E)$