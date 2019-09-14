DROP VIEW IF EXISTS q0, q1i, q1ii, q1iii, q1iv, q2i, q2ii, q2iii, q3i, q3ii, q3iii, q4i, q4ii, q4iii, q4iv, q4v;

-- Question 0
CREATE VIEW q0(era) 
AS
  SELECT MAX(era) FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people 
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear 
  FROM people 
  WHERE namefirst LIKE '% %';
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, 
         AVG(height) AS avgheight, 
         COUNT(*) AS count
  FROM people 
  GROUP BY birthyear 
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, 
         AVG(height) AS avgheight, 
         COUNT(*) AS count
  FROM people
  GROUP BY birthyear
  HAVING AVG(height) > 70
  ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, hf.playerid, yearid
  FROM halloffame AS hf 
    INNER JOIN people AS p ON hf.playerid = p.playerid
  WHERE hf.inducted = 'Y'
  ORDER BY yearid DESC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT namefirst, namelast, hf.playerid, s.schoolid, hf.yearid
  FROM halloffame AS hf 
    INNER JOIN people AS p ON hf.playerid = p.playerid
    INNER JOIN collegeplaying AS c ON c.playerid = p.playerid
    INNER JOIN schools AS s ON s.schoolid = c.schoolid
  WHERE hf.inducted = 'Y' AND s.schoolstate = 'CA'
  ORDER BY hf.yearid DESC, s.schoolid, hf.playerid
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT hf.playerid, p.namefirst, p.namelast, s.schoolid
  FROM halloffame AS hf 
    INNER JOIN people AS p ON hf.playerid = p.playerid
    LEFT OUTER JOIN collegeplaying AS c ON c.playerid = p.playerid
    LEFT OUTER JOIN schools AS s ON s.schoolid = c.schoolid
  WHERE hf.inducted = 'Y'
  ORDER BY hf.playerid DESC, hf.playerid, s.schoolid
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, namefirst, namelast, yearid,
    cast((h - h2b - h3b - hr + 2 * h2b + 3 * h3b + 4 * hr) AS FLOAT) 
    / (ab) AS slg
  FROM people AS p INNER JOIN batting AS b ON p.playerid = b.playerid
  WHERE b.ab > 50
  ORDER BY slg DESC, b.yearid, p.playerid
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid, p.namefirst, p.namelast,
    cast(sum(h) - sum(h2b) - sum(h3b) - sum(hr) + (2 * sum(h2b)) + (3 * sum(h3b)) + (4 * sum(hr)) AS FLOAT) 
    / (sum(AB)) AS lslg
  FROM people AS p INNER JOIN batting AS b ON b.playerid = p.playerid
  WHERE b.ab > 0
  GROUP BY p.playerid
  HAVING(SUM(b.ab) > 50)
  ORDER BY lslg DESC, playerid
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  WITH Q AS (
    SELECT p.playerid, 
           cast(sum(h) - sum(h2b) - sum(h3b) - sum(hr) + (2 * sum(h2b)) + (3 * sum(h3b)) + (4 * sum(hr)) AS FLOAT) 
           / (sum(AB)) AS lslg
    FROM people AS p
          INNER JOIN batting AS b ON b.playerid = p.playerid
    WHERE b.ab > 0
    GROUP BY p.playerid
    HAVING(SUM(b.ab) > 50))
  SELECT p.namefirst, p.namelast, q.lslg
  FROM people AS p INNER JOIN Q AS q ON p.playerid = q.playerid
  WHERE q.lslg > (SELECT lslg FROM q WHERE playerid = 'mayswi01')
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg, stddev)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary), stddev(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  WITH 
    X AS (SELECT MIN(salary), MAX(salary)
             FROM salaries WHERE yearid = 2016), 
    Y AS (SELECT i AS binid, 
                 i*(X.max-X.min)/10 + X.min AS low,
                 (i+1)*(X.max-X.min)/10.0 + X.min AS high
          FROM generate_series(0,9) AS i, X)
  SELECT binid, low, high, COUNT(*) 
  FROM Y INNER JOIN salaries AS s 
         ON s.salary >= Y.low 
            AND (s.salary < Y.high OR binid = 9 AND s.salary <= Y.high)
            AND yearid = '2016'
  GROUP BY binid, low, high
  ORDER BY binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  WITH X AS (SELECT yearid, MIN(salary), MAX(salary), AVG(salary)
             FROM salaries 
             GROUP BY yearid)
  SELECT b.yearid,
         b.min - a.min AS mindiff,
         b.max - a.max AS maxdiff,
         b.avg - a.avg AS avgdiff
  FROM X AS a INNER JOIN X AS b ON b.yearid = a.yearid + 1
  ORDER BY b.yearid
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  WITH X AS(SELECT yearid, MAX(salary) FROM salaries
            WHERE yearid IN (2000,2001)
            GROUP BY yearid)
  SELECT m.playerid, namefirst, namelast, salary, x.yearid
  FROM people AS m 
       NATURAL JOIN salaries AS s
       INNER JOIN X AS x ON salary = x.max AND s.yearid = x.yearid
;

-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT tbl.teamid AS team, 
         max(salary) - min(salary) AS diffavg 
  FROM
    (SELECT a.playerid, a.teamid, salaries.salary 
      FROM allstarfull AS a
        INNER JOIN salaries ON a.playerid = salaries.playerId 
        AND a.yearid = 2016 
        AND salaries.yearid = 2016) AS tbl
  GROUP BY tbl.teamid
;

