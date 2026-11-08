# StaySense: Hotel Booking Analytics

Analysis of ~87K hotel bookings to find **where revenue is tied up in cancellations, when cancellations happen, and how a hotel could plan overbooking.**

**Tools:** Python (Pandas) | MySQL 8 | Power BI (dashboard in progress)
**Dataset:** [Hotel Booking Demand](https://www.kaggle.com/datasets/jessemostipak/hotel-booking-demand) (Kaggle), bookings for a City Hotel and a Resort Hotel, July 2015 to August 2017

---

## Business Problem

Cancelled bookings leave rooms empty and revenue uncertain. StaySense answers three questions:

| Module | Question |
|---|---|
| **LeakGuard** | How much booked revenue is tied to cancelled bookings, and from which segments? |
| **LeadLens** | How does the time between booking and arrival affect cancellation? |
| **OverbookIQ** | How does cancellation vary by month and hotel, and what overbooking buffer does that suggest? |

---

## Project Workflow

1. **Clean the data** in Python/Pandas (`notebooks/01_cleaning.ipynb`)
2. **Load** the cleaned data into MySQL (`sql/01_create_table.sql`)
3. **Analyze** with SQL (`sql/staysense_analysis.sql`)
4. **Visualize** in Power BI (in progress)

---

## 1. Data Cleaning

Raw data: 119,390 rows. Cleaned data: **87,222 rows, 36 columns**.

| Issue | Action |
|---|---|
| `company` column ~94% null | Dropped the column |
| `agent` nulls | Filled with 0 (no agent / direct booking) |
| `country` nulls | Filled with "Unknown" |
| `children` nulls | Filled with 0 |
| 180 zero-guest bookings | Removed |
| 1 negative ADR row | Removed |
| 32,001 exact duplicate rows | Removed (see note below) |
| 1,960 rows with zero ADR | Kept, flagged with `has_revenue`; excluded from revenue queries only |

**New columns:** `total_nights`, `total_revenue` (ADR x nights), `arrival_date`, `lead_time_bucket` (0-30, 31-90, 91-180, 181-365, 365+), `has_revenue`.

**Duplicates note:** the dataset has no booking ID, so duplicates were identified as exact matches across all columns. The removed rows were **63.1% cancelled**, versus 27.5% in the retained data, so this choice changes the overall cancellation rate from **37.0% to 27.5%**. All results below use the deduplicated data. If some removed rows were genuine separate bookings, true cancellation and revenue-at-risk figures would be higher.

---

## 2. Key Findings

### LeakGuard: revenue at risk from cancellations

Based on bookings with a usable rate (ADR > 0) and at least one night.

- **33.3%** of booked revenue (about 11.5M of 34.5M, in the dataset's unspecified currency units) sits in cancelled bookings.
- **Online travel agents (Online TA)** account for about **81%** of revenue at risk, and 41.7% of their booked revenue is cancelled, versus 15-26% for other segments.

| Market segment | Revenue at risk | % of segment revenue cancelled |
|---|---|---|
| Online TA | 9,292,902 | 41.7% |
| Direct | 929,714 | 19.1% |
| Offline TA/TO | 821,009 | 15.2% |
| Groups | 315,620 | 25.5% |
| Corporate | 110,415 | 18.6% |
| Aviation | 14,065 | 16.9% |

| Hotel | Revenue at risk | % cancelled |
|---|---|---|
| City Hotel | 6,614,456 | 35.2% |
| Resort Hotel | 4,869,587 | 31.0% |

*Complementary and Undefined segments are negligible in volume and omitted from this table.*

### LeadLens: cancellation by lead time

| Lead time (days) | Bookings | Cancellation rate |
|---|---|---|
| 0-30 | 34,522 | 16.4% |
| 31-90 | 22,720 | 32.0% |
| 91-180 | 18,224 | 35.0% |
| 181-365 | 11,192 | 39.7% |
| 365+ | 564 | 40.8% (small sample) |

The biggest jump is between 0-30 and 31-90 days. The pattern holds **within both Online TA and other segments**, so lead time is a signal on its own, not just a segment effect:

| Lead time (days) | Online TA | Other segments |
|---|---|---|
| 0-30 | 21.4% | 10.9% |
| 31-90 | 39.0% | 17.8% |
| 91-180 | 43.4% | 19.6% |
| 181-365 | 51.7% | 24.1% |

Online TA cancels about twice as often as other segments at every lead time. (The Online TA 365+ group has only 15 bookings and is not interpreted.)

### OverbookIQ: monthly cancellation and suggested buffer

- **Resort Hotel is strongly seasonal:** cancellation rate ranges from **14.0% in January to 32.4% in August** (winter months about 14-19%, June to August about 30-32%).
- **City Hotel is steadier:** 25-34% across the year, highest in April (34.4%) and July (33.1%).
- A single overbooking buffer would not suit the Resort Hotel; a buffer that varies by month would. The suggested buffer ranges from about 7% (January) to 16% (August) for the Resort and 13-17% for the City Hotel.

The suggested buffer is **50% of the monthly cancellation rate**. This safety factor is an assumption, not a validated model.

---

## 3. Recommendations

- Test stricter cancellation terms or deposits for **Online TA** bookings first, since they drive most of the revenue at risk.
- Treat bookings made **more than 30 days ahead** as higher risk, and more so beyond 180 days.
- Use a **month-specific** overbooking buffer for the Resort Hotel, and a roughly flat one for the City Hotel.

---

## 4. Limitations

- **Revenue at risk is not money lost.** It is ADR x nights for cancelled bookings; some rooms may have been resold or covered by non-refundable deposits.
- The reasons behind Online TA cancellations (for example, free-cancellation policies) are plausible hypotheses; this dataset cannot confirm them.
- Duplicate removal changes the overall cancellation rate (see above); no booking ID exists to verify duplicates.
- Zero-ADR bookings (1,960 before deduplication) and zero-night bookings (591 in the cleaned data) are excluded from revenue figures, so revenue figures are conservative.
- The data spans July 2015 to August 2017, so July and August include three years of data and other months two. Monthly results pool years.
- There is no hotel capacity or compensation-cost data, so the overbooking buffer is a rule of thumb, not a recommendation to over-sell by that amount.

---

## Repository Structure

```
StaySense/
├── data/
│   └── hotel_bookings_clean.csv
├── notebooks/
│   └── 01_cleaning.ipynb
├── sql/
│   ├── 01_create_table.sql
│   └── staysense_analysis.sql
├── dashboard/              # Power BI file and screenshots (in progress)
└── README.md
```

## How to Reproduce

1. Download `hotel_bookings.csv` from Kaggle and place it in `data/`.
2. Run `notebooks/01_cleaning.ipynb` to produce `data/hotel_bookings_clean.csv`.
3. In MySQL, run `sql/01_create_table.sql`, then import the cleaned CSV into the `bookings` table.
4. Run the queries in `sql/staysense_analysis.sql`.

## Next Steps

- Build the 3-page Power BI dashboard (overview, LeakGuard + LeadLens, OverbookIQ)

---

**Author:** Samrudhi | [GitHub](https://github.com/samrudhichitrakar)
