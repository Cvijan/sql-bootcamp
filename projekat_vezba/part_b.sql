-- 1. и 2. Сезона, укупно и по месту (за укупно избаците x.venue из SELECT и GROUP BY)
WITH timovi AS (
  SELECT season, home_team_id AS team_id, 'home' AS venue, home_goals AS dati, away_goals AS primljeni
  FROM matches WHERE status = 'played'
  UNION ALL
  SELECT season, away_team_id, 'away', away_goals, home_goals
  FROM matches WHERE status = 'played'
)
SELECT x.venue, COUNT(*) AS utakmice,
       COUNT_IF(dati > primljeni) AS pobede, 
       COUNT_IF(dati = primljeni) AS nereseno, 
       COUNT_IF(dati < primljeni) AS porazi,
       SUM(dati) AS dati, SUM(primljeni) AS primljeni,
       SUM(CASE WHEN dati > primljeni THEN 3 
                WHEN dati = primljeni THEN 1 
                ELSE 0 
            END) AS bodovi
FROM timovi x JOIN teams t ON x.team_id = t.team_id
WHERE x.season = '2024/25' AND t.team_name = 'Kingsbridge City'
GROUP BY x.venue;

-- 3. Публика
SELECT ROUND(AVG(m.attendance)) AS prosek,
       ROUND(AVG(100 * m.attendance / s.capacity), 1) AS popunjenost_pct,
       COUNT(*) - COUNT(m.attendance) AS bez_podatka
FROM matches m
JOIN teams    t ON m.home_team_id = t.team_id
JOIN stadiums s ON m.stadium_id   = s.stadium_id
WHERE m.season = '2024/25' AND m.status = 'played' AND t.team_name = 'Kingsbridge City';

-- 4. Стрелци (за асистенте: JOIN players p ON e.related_player_id = p.player_id, и LIMIT 1)
SELECT p.first_name, p.last_name, COUNT(*) AS golovi
FROM match_events e
JOIN matches m ON e.match_id  = m.match_id
JOIN players p ON e.player_id = p.player_id
JOIN teams   t ON e.team_id   = t.team_id
WHERE m.season = '2024/25' AND e.event_type IN ('goal', 'penalty_goal') AND t.team_name = 'Kingsbridge City'
GROUP BY p.player_id, p.first_name, p.last_name
ORDER BY golovi DESC
LIMIT 3;

-- 5. Картони: клуб има 38 утакмица; лига 380 утакмица, тј. 760 наступа тимова
SELECT ROUND(COUNT_IF(t.team_name = 'Kingsbridge City') / 38, 2) AS klub_po_utakmici,
       ROUND(COUNT(*) / 760, 2)                                    AS liga_po_timu_po_utakmici
FROM match_events e
JOIN matches m ON e.match_id = m.match_id
JOIN teams   t ON e.team_id  = t.team_id
WHERE m.season = '2024/25' AND m.status = 'played'
  AND e.event_type IN ('yellow_card', 'second_yellow', 'red_card');

-- 5. Тренери - користимо team_matches (appendix.sql)
SELECT ms.manager_name, COUNT(*) AS utakmice, SUM(tm.points) AS bodovi,
       ROUND(AVG(tm.points), 2) AS bodova_po_utakmici
FROM team_matches tm
JOIN teams t ON tm.team_id = t.team_id
JOIN manager_spells ms
  ON ms.team_id = tm.team_id
 AND DATE(tm.kickoff_ts) BETWEEN ms.start_date AND COALESCE(ms.end_date, DATE'9999-12-31')
WHERE tm.season = '2024/25' AND t.team_name = 'Kingsbridge City'
GROUP BY ms.manager_name;

-- 6. Пример: догађаји са непостојећим играчем
SELECT e.event_id, e.player_id, e.event_type
FROM match_events e LEFT JOIN players p ON e.player_id = p.player_id
WHERE e.player_id IS NOT NULL AND p.player_id IS NULL;