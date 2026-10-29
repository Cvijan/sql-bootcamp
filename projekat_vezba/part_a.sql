-- А1 -> 52 утакмице
SELECT COUNT(*) FROM matches
WHERE kickoff_ts >= '2024-12-01' AND kickoff_ts < '2025-01-01';

-- А2 -> 26. 10. 2024, Northport United 6-3 Newbury Forest (9 голова)
SELECT m.kickoff_ts, h.team_name AS home_team, m.home_goals, m.away_goals, a.team_name AS away_team
FROM matches m
JOIN teams h ON m.home_team_id = h.team_id
JOIN teams a ON m.away_team_id = a.team_id
ORDER BY m.home_goals + m.away_goals DESC, m.kickoff_ts
LIMIT 1;

-- А3 -> 19 судија (један судија из табеле referees још није судио)
SELECT COUNT(DISTINCT referee_id) FROM matches;

-- А4 -> 25 утакмица
SELECT COUNT(*) FROM matches
WHERE season = '2023/24' AND weather IN ('snow', 'fog');

-- А5 -> 17 без пријављене посете, 1 без публике
SELECT COUNT(*) - COUNT(attendance) AS bez_podatka,
       COUNT_IF(attendance = 0)     AS bez_publike
FROM matches;

-- А6 -> 2023/24: 3,57; 2024/25: 3,47 (са INNER JOIN погрешно 3,76 и 3,66)
WITH karton AS (
  SELECT match_id, COUNT(*) AS n FROM match_events
  WHERE event_type IN ('yellow_card', 'second_yellow', 'red_card')
  GROUP BY match_id
)
SELECT 
    m.season, 
    ROUND(AVG(COALESCE(k.n, 0)), 2) AS kartona_po_utakmici
FROM matches m 
LEFT JOIN karton k ON m.match_id = k.match_id
WHERE m.status = 'played'
GROUP BY m.season;

-- А7 -> 81 играч
SELECT COUNT(DISTINCT player_id) FROM match_events
WHERE event_type IN ('red_card', 'second_yellow');

-- А8 -> Ashford Rovers, 77 жутих картона
SELECT 
    t.team_name, 
    COUNT(*) AS zuti
FROM match_events e
JOIN matches m ON e.match_id = m.match_id
JOIN teams   t ON e.team_id  = t.team_id
WHERE m.season = '2024/25' 
    AND e.event_type IN ('yellow_card', 'second_yellow')
GROUP BY t.team_name
ORDER BY zuti DESC;

-- А9 -> 370 утакмица (просек 3,52 картона по утакмици)
WITH karton AS (
  SELECT m.match_id, COUNT(e.event_id) AS n
  FROM matches m
  LEFT JOIN match_events e
    ON m.match_id = e.match_id AND e.event_type IN ('yellow_card', 'second_yellow', 'red_card')
  WHERE m.status = 'played'
  GROUP BY m.match_id
)
SELECT COUNT(*) 
FROM karton 
WHERE n > (SELECT AVG(n) FROM karton);

-- А10 -> Castlebrook United, 77 бодова
WITH timovi AS (
  SELECT 
    season, 
    home_team_id AS team_id,
    home_goals AS dati, 
    away_goals AS primljeni
  FROM matches WHERE status = 'played'
  UNION ALL
  SELECT 
    season, 
    away_team_id, 
    away_goals, 
    home_goals
  FROM matches WHERE status = 'played'
)
SELECT t.team_name,
       SUM(CASE WHEN dati > primljeni THEN 3 
                WHEN dati = primljeni THEN 1 
                ELSE 0 
            END) AS bodovi,
       SUM(dati - primljeni) AS gol_razlika
FROM timovi x 
JOIN teams t ON x.team_id = t.team_id
WHERE x.season = '2023/24'
GROUP BY t.team_name
ORDER BY bodovi DESC, gol_razlika DESC;