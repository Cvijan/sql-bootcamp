-- В1 -> Northport City – Queensport FC, 12.5.2024. - 40.844, око 6.563 изнад просека стадиона
SELECT 
    h.team_name AS domacin, 
    a.team_name AS gost, 
    m.kickoff_ts, 
    m.attendance,
    ROUND(m.attendance - AVG(m.attendance) OVER (PARTITION BY m.stadium_id)) AS razlika
FROM matches m
JOIN teams h ON m.home_team_id = h.team_id
JOIN teams a ON m.away_team_id = a.team_id
WHERE m.season = '2023/24'
ORDER BY razlika DESC NULLS LAST;

-- В2 -> 1. Pablo Fernández (9); 2. Filip Petrović, Lucas Pereira и Eirik Solberg (по 7)
SELECT 
    p.first_name, 
    p.last_name, 
    COUNT(*) AS asistencije,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rang
FROM match_events e
JOIN matches m ON e.match_id = m.match_id
JOIN players p ON e.related_player_id = p.player_id
WHERE m.season = '2024/25' 
    AND e.event_type IN ('goal', 'penalty_goal')
GROUP BY p.player_id, p.first_name, p.last_name
QUALIFY rang <= 2
ORDER BY asistencije DESC;

-- В3 -> 20 редова (у Northport United и Riverton Athletic: Leo Marsh, 25. 8. 2024)
SELECT 
    t.team_name, 
    p.first_name, 
    p.last_name, 
    m.kickoff_ts, 
    e.minute
FROM match_events e
JOIN matches m ON e.match_id  = m.match_id
JOIN teams   t ON e.team_id   = t.team_id
JOIN players p ON e.player_id = p.player_id
WHERE m.season = '2024/25' 
    AND e.event_type IN ('goal', 'penalty_goal')
QUALIFY ROW_NUMBER() OVER (PARTITION BY e.team_id ORDER BY m.kickoff_ts, e.minute, e.event_id) = 1
ORDER BY t.team_name;

-- В4 -> децембар 2024: 145 голова, 49 више него у новембру
WITH po_mesecima AS (
  SELECT 
    DATE_TRUNC('MONTH', kickoff_ts) AS mesec, 
    SUM(home_goals + away_goals) AS golovi
  FROM matches
  WHERE season = '2024/25' AND status = 'played'
  GROUP BY mesec
)
SELECT mesec, golovi,
       golovi - LAG(golovi) OVER (ORDER BY mesec) AS promena
FROM po_mesecima
ORDER BY promena DESC NULLS LAST;

-- В5 -> Kingsbridge City, 18. 1. 2025
WITH timovi AS (
  SELECT match_id, season, kickoff_ts, home_team_id AS team_id, home_goals AS dati
  FROM matches WHERE status = 'played'
  UNION ALL
  SELECT match_id, season, kickoff_ts, away_team_id, away_goals
  FROM matches WHERE status = 'played'
),
tekuce AS (
  SELECT team_id, kickoff_ts,
         SUM(dati) OVER (PARTITION BY team_id ORDER BY kickoff_ts, match_id
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS golovi_do_sada
  FROM timovi
  WHERE season = '2024/25'
)
SELECT t.team_name, x.kickoff_ts, x.golovi_do_sada
FROM tekuce x 
JOIN teams t ON x.team_id = t.team_id
WHERE x.golovi_do_sada >= 50
ORDER BY x.kickoff_ts
LIMIT 1;