# Cybersecurity Threat Analytics

A Python and SQLite investigation of **40,000 synthetic cybersecurity events** for a hypothetical Security Operations Center (SOC). The project emphasizes explainable analysis, statistical uncertainty, and honest model evaluation. It does not demonstrate real-world attack detection or prevention.

**Dataset.** The supplied CSV has 25 original columns and timestamps from January 1, 2020 to October 11, 2023. The original notebook attributes it to [Incribo on Kaggle](https://www.kaggle.com/datasets/teamincribo/cyber-security-attacks). Generation details and the supplied file's provenance are not independently verified. The geographic components were supplied with the original project.

**Questions.** How do categories vary across segments and devices? Does severity relate to recorded response? How do monthly volumes and response shares change? Which associations merit investigation? Can protocol prediction outperform a simple baseline among events with anomaly score > 50?

**Tools and method.** Pandas/NumPy for audits and transparent feature engineering; Matplotlib/Seaborn and GeoPandas for visualization; Python's built-in SQLite for seven analytical queries using CTEs, joins, CASE, window functions, and date aggregation; SciPy for association tests, effect sizes, and intervals; scikit-learn for training-only preprocessing, cross-validation, limited tuning, and holdout evaluation. The notebook has five sections, with all results saved.

**Verified findings**

- No exact duplicate rows or invalid timestamps were found. Six fields are 49.63%–50.17% blank; blanks are not assumed to mean a confirmed negative detection. All 18,370 ICMP events have populated port fields, revealing a synthetic inconsistency.
- DDoS contributes 13,428 events (33.57%). Segment attack mixes differ from the overall mix by at most 0.60 percentage points. Manipur has 2,978 assigned events (7.45%); no exposure data supports interpreting that as greater risk. All event state labels match the supplied map.
- Of 13,382 high-severity events, 4,460 are labeled Ignored: 33.33%, with an illustrative 95% Wilson interval of 32.53%–34.13%. Blocked labels comprise 33.82% of all events; neither measure establishes prevention effectiveness.
- The 45 complete calendar months contain 788–950 events each. October 2023 is partial and excluded from comparable monthly volume changes; continuous monitoring is not verified.
- Chi-square tests find small effects for attack type vs segment (Cramér's V = 0.0075), severity vs action (V = 0.0065), and attack type vs protocol among high-anomaly events (V = 0.0098). Spearman correlation between anomaly score and packet length is −0.0036. None rejects its null at 5% after Holm adjustment across these four comparisons (all adjusted p = 1.000). This does not prove independence.

**Machine-learning results**

The original setup reproduces **37.56% Random Forest accuracy**, below its **46.22% majority baseline**, on the original unstratified test split. There are 20,130 events above the original anomaly threshold; 4,026 are in each evaluation holdout.

Improved candidates share a new stratified 80/20 split and identical three-fold stratified training CV. Imputation, scaling, and one-hot encoding are fitted within folds. A two-setting search per non-dummy candidate selects by macro-F1. The base features are anomaly score, packet length, ports, packet type, traffic type, and segment; engineered features add cyclic time, weekday, port bands, and OS family. Downstream annotations, identities, geographic labels, and protocol indicators are excluded. Anomaly score is retained only for the explicitly retrospective task because its timing is undocumented.

| Model / features | CV macro-F1 | Test accuracy | Test macro-F1 |
|---|---:|---:|---:|
| Majority dummy | 0.2084 | 45.48% | 0.2084 |
| Logistic Regression / base | 0.2084 | 45.48% | 0.2084 |
| Logistic Regression / engineered | 0.2084 | 45.48% | 0.2084 |
| Random Forest / engineered | 0.2108 | 45.40% | 0.2099 |

CV selects the forest (150 trees, minimum leaf size 10, unlimited depth). Its test macro-precision is 0.2286 and macro-recall 0.3331. ICMP recall is 99.67%, TCP recall 0.26%, and UDP recall 0%: it largely predicts the majority class. Selected-minus-dummy accuracy is **−0.07 percentage points**, with a paired bootstrap 95% interval of **−0.22 to +0.07 points**. Logistic feature engineering gives no CV macro-F1 gain. These results provide no convincing evidence of useful protocol prediction. The two split designs prevent treating the difference from the original accuracy as a controlled model improvement.

**Recommendations and limits.** Use high-severity/Ignored records to define a hypothetical case-review exercise, collect exposure denominators before prioritizing groups, and track response shares alongside coverage. Protocol is usually already observed in telemetry; predicting it is a methodological exercise, not an attack detector. Synthetic labels, ambiguous missingness, heuristic device labels, unverified locations/boundaries, ICMP/port inconsistencies, and absent benign cases limit interpretation. Inference assumes independent events. Random-split evaluation and exploratory importance do not establish performance on future periods or unseen entities. No causal security benefit, blocking rule, or cost saving follows from this file.

**Project files**

```text
.
├── data/
│   ├── cybersecurity_attacks.csv
│   └── Indian_states.{shp,shx,dbf,prj}
├── notebooks/
│   ├── CyberAttackFinalProject_original.ipynb
│   └── Cybersecurity_Analysis.ipynb
├── sql/
│   └── analysis.sql
├── README.md
├── requirements.txt
└── .gitignore
```

The supplied HTML and PowerPoint exports also remain at the root as unchanged source artifacts. Original notebook/data/shapefile contents were verified byte-for-byte after organization; the DBF stem was capitalized to match its shapefile. The original notebook retains its historical paths and dependencies; use the improved notebook for the runnable analysis. No separate scripts, database files, dashboard, or production infrastructure are required.

**Run the improved notebook**

From this project folder, use Python 3.9–3.12 (execution verified with 3.9.6):

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python -m jupyter lab notebooks/Cybersecurity_Analysis.ipynb
```

Select the virtual environment's kernel and choose **Restart Kernel and Run All Cells**. Paths work from the project root or `notebooks/`. SQLite is in memory and rebuilt each run; it needs SQLite 3.25+ for window functions. The notebook completed all 21 code cells with no execution errors, and the SQL totals reconcile with the cleaned records. Package versions are displayed in the notebook and recorded in `requirements.txt`.
