USE guest_test;

SELECT ename AS ename_and_dname,deptno
FROM emp
WHERE deptno=10
UNION ALL
SELECT '---------------------',NULL
FROM t1
UNION ALL
SELECT dname,deptno
FROM dept
-- ---------------------------------

SELECT deptno
FROM dept
WHERE deptno NOT IN (SELECT deptno FROM emp)

-- ------------------------------------------

SELECT *
FROM DEPT
WHERE DEPTNO NOT IN (SELECT DEPTNO FROM NEW_DEPT)
-- -------------------------------------------

SELECT deptno
FROM dept d
WHERE NOT EXISTS (SELECT NULL FROM new_dept n WHERE d.deptno=n.deptno )
-- --------------------------------------------------

SELECT d.* 
FROM dept d LEFT JOIN emp e ON (
d.deptno = e.deptno
) 
WHERE e.ename IS NULL

SELECT e.* 
FROM sign_event e LEFT JOIN sign_guest g ON (
e.id = g.event_id
)
WHERE g.realname IS NULL

-- ----------------------------------------------

SELECT e.ename, d.loc, eb.received
FROM emp e INNER JOIN dept d
ON( e.deptno = d.deptno )
LEFT JOIN emp_bonus eb
ON( e.empno = eb.empno )
ORDER BY 2 

-- -------------------------------------------------
CREATE VIEW V
AS
SELECT * FROM emp WHERE DEPTNO != 10
UNION ALL
SELECT * FROM EMP WHERE ENAME = 'WARD'

SELECT * FROM V

SELECT *
FROM (
	-- from子查询返回emp表的一个视图e，之所以不直接用emp表，是为了增加一个cnt字段，
	-- 用来表示是否有重复的数据行，当cnt>1时，说明该数据有重复
	SELECT e.`EMPNO`,e.`ENAME`,e.`JOB`,e.`MGR`,e.`HIREDATE`,e.`SAL`,e.`COMM`,e.`DEPTNO`,COUNT(*) AS cnt
	FROM emp e
	GROUP BY empno,ename,job,mgr,hiredate,sal,comm,deptno  -- 这句是为了count(*)统计有没有重复的数据
     ) e
WHERE NOT EXISTS (
	SELECT *
	FROM (
		SELECT v.`EMPNO`,v.`ENAME`,v.`JOB`,v.`MGR`,v.`HIREDATE`,v.`SAL`,v.`COMM`,v.`DEPTNO`,COUNT(*) AS cnt
		FROM v
		GROUP BY empno,ename,job,mgr,HIREDATE,sal,comm,deptno
	     ) v
	-- 如果按照以下条件连接，得到的结果就是两张表相同的数据，
	-- 这部分数据会在 select * from emp e的时候被丢弃，而只剩下emp里独有的数据
	WHERE e.`EMPNO` = v.`EMPNO`
	AND e.`ename` = v.`ENAME`
	AND e.`JOB` = v.`JOB`
	AND e.`MGR` = v.`MGR`
	AND e.`HIREDATE` = v.`HIREDATE`
	AND e.`SAL` = v.`SAL`
	AND e.`DEPTNO` = v.`DEPTNO`
	AND e.cnt = v.cnt
	AND COALESCE(e.comm,0) = COALESCE(v.comm,0)
)
UNION ALL  -- 叠加下面的查询结果
-- 以下是将emp和v的位置对调，找出v里独有的数据，
SELECT *
FROM (
SELECT v.`EMPNO`,v.`ENAME`,v.`JOB`,v.`MGR`,v.`HIREDATE`,v.`SAL`,v.`COMM`,v.`DEPTNO`,COUNT(*) AS cnt
FROM v
GROUP BY empno,ename,JOB,mgr,HIREDATE,sal,comm,deptno
) v
WHERE NOT EXISTS(
SELECT NULL
FROM (
SELECT e.empno, e.ename, e.job, e.mgr, e.hiredate, e.sal, e.comm, e.deptno, COUNT(*) AS cnt
FROM emp e
GROUP BY empno,ename,job,mgr,hiredate,sal,comm,deptno
) e
WHERE e.empno = v.`EMPNO`
AND e.ename = v.`ENAME`
AND e.job = v.`JOB`
AND e.mgr = v.`MGR`
AND e.hiredate = v.`HIREDATE`
AND e.sal = v.`SAL`
AND e.deptno = v.`DEPTNO`
AND e.cnt = v.cnt
AND COALESCE(e.comm,0) = COALESCE(v.comm,0)
)

-- 简单判断两个表行数是否相等 -------------------------
SELECT COUNT(*)
FROM emp
UNION
SELECT COUNT(*)
FROM v

-- ----------------------------------------------------------
-- 使用distinct关键字消除重复行------------
SELECT deptno,
SUM(DISTINCT sal) AS total_sal,
SUM(bonus) AS total_bonus
FROM (
	SELECT e.empno,e.ename,e.sal,e.deptno,
	e.sal * CASE WHEN eb.type=1 THEN 0.1
	WHEN eb.type=2 THEN 0.2
	WHEN eb.type=3 THEN 0.3
	END AS bonus
	FROM emp e, emp_bonus eb
	WHERE e.empno = eb.empno
	AND e.deptno = 10
) X
GROUP BY deptno

-- 使用内联试图先求和，再连接----------------------

SELECT x.deptno,total_sal,
SUM(e.sal* CASE WHEN eb.type=1 THEN 0.1
WHEN eb.type=2 THEN 0.2
WHEN eb.type=3 THEN 0.3
END) AS total_bonus
FROM (
	SELECT deptno,SUM(sal) AS total_sal
	FROM emp
	WHERE deptno=10
	GROUP BY deptno
) X, emp_bonus eb, emp e
WHERE e.empno = eb.empno
AND x.deptno = e.deptno
GROUP BY x.deptno,total_sal

-- 使用外连接和distinct----------------------------------------------------------
SELECT deptno,
SUM(DISTINCT sal) AS total_sal,
SUM(bonus) AS total_bonus
FROM(
	SELECT e.empno,
	e.ename,
	e.deptno,
	e.sal,
	e.sal* CASE WHEN eb.type=1 THEN 0.1
	WHEN eb.type=2 THEN 0.2
	WHEN eb.type=3 THEN 0.3
	END AS bonus
	FROM emp e LEFT JOIN emp_bonus eb
	ON e.empno = eb.empno
	WHERE e.deptno=10
) d
GROUP BY deptno

-- --------------------------------------------------------------- 
-- full join
SELECT d.deptno,d.dname,e.ename
FROM dept d FULL JOIN emp e
ON ( d.deptno=e.deptno ) 

-- --------------------------------------------------
INSERT INTO dept(deptno,dname,loc) 
VALUES('50','PROGRAMMING','BALTIMORE')

-- -------------------------------------------
-- 复制dept表，不需要数据
CREATE TABLE dept_mid
AS
SELECT *
FROM dept
WHERE 1=0
-- -------------------------------------------
UPDATE emp e
SET e.sal = e.sal*1.10
WHERE e.job='salesman'

-- ------------------------------------------
UPDATE emp e
SET e.sal=e.sal*1.10
WHERE EXISTS(SELECT NULL 
		FROM new_sal ns 
		WHERE e.deptno=ns.deptno)
		
-- --------------------------------------------
-- 用new_sal表里的sal值更新emp表里有相同deptno的记录的sal值
UPDATE emp e,new_sal ns
SET e.sal=ns.sal, e.comm=ns.sal/2 
WHERE ns.deptno=e.deptno

SELECT * FROM emp e,new_sal ns
WHERE e.deptno=ns.deptno

-- ----------------------------------------------
SELECT * FROM emp ORDER BY deptno

DELETE FROM emp
WHERE deptno IN (
SELECT deptno
FROM dept_accidents
GROUP BY deptno`guest_test``db`
HAVING COUNT(1)>=3
) 

-- --------------------------------------------
SELECT SUBSTR(e.ename,iter.pos,1) AS c
FROM (SELECT ename FROM emp WHERE ename='KING') e,
     (SELECT id AS pos FROM t10) iter
WHERE iter.pos <= LENGTH(e.ename)

-- ---------------------------------------------

SELECT 'apple''s core' FROM t1
-- ---------------------------------------------

SELECT (LENGTH('10,clark,manager')-LENGTH(REPLACE('10,clark,manager',',','')))/LENGTH(',')
AS cnt

-- ---------------------------------------------------------

SELECT ename,
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(ename,'A',''),'E',''),'I',''),'O',''),'U','') AS stripped
FROM emp
-- ------------------------------------------------------------

-- truncate table emp
SELECT * FROM v1

SELECT DATA
FROM V1
WHERE DATA REGEXP '[^0-9a-zA-Z]' = 0

SELECT 'helloll' REGEXP '[n,m]'

-- -----------------------------------------------------
SELECT ename 
FROM emp
ORDER BY SUBSTR(ename,LENGTH(ename)-1,2)
-- -------------------------------------------------------

SELECT deptno,
GROUP_CONCAT(ename ORDER BY empno SEPARATOR',') AS emps
FROM emp
GROUP BY deptno

-- -------------------------------------------------------

SELECT empno,ename,sal,deptno
FROM emp
WHERE empno IN (
SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(empnos.vals,',',iter.pos),',',-1)
-- select *
FROM (SELECT id AS pos FROM t10) iter,
(SELECT '7654,7698,7782,7788' AS vals FROM t1) empnos
WHERE iter.pos <= (LENGTH(empnos.vals)-LENGTH(REPLACE(empnos.vals,',','')))+1 
)

-- -----------------------------------------------------------------------
SELECT ename,GROUP_CONCAT(x.c ORDER BY c SEPARATOR'') AS ordered_ename
FROM
(SELECT ename,SUBSTR(e.ename,iter.pos,1) c
FROM (SELECT id AS pos FROM t10) iter,
(SELECT ename FROM emp) e
WHERE iter.pos <= LENGTH(e.ename)
)X
GROUP BY ename

-- -----------------------------------------------------------------------
-- 如果确定了要截取的子串，就不用和基础表做笛卡尔积了，直接用substring_index就实现了
-- 也可以把整个字符串都分隔了，根据需要取第几个子串
SELECT pos,`name`
FROM( 
SELECT iter.pos,SUBSTRING_INDEX(SUBSTRING_INDEX(v2.name,',',iter.pos),',',-1) AS `name`
FROM (SELECT id AS pos FROM t10) iter,
v2
WHERE iter.pos <= (LENGTH(v2.`name`)-LENGTH(REPLACE(v2.`name`,',',''))+1) 
) X
WHERE x.pos=2  -- 选择取第几个子串

-- ---------------------------------------------------------------------------

SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(y.ip,'.',1),'.',-1) AS a,
SUBSTRING_INDEX(SUBSTRING_INDEX(y.ip,'.',2),'.',-1) AS b,
SUBSTRING_INDEX(SUBSTRING_INDEX(y.ip,'.',3),'.',-1) AS c,
SUBSTRING_INDEX(SUBSTRING_INDEX(y.ip,'.',4),'.',-1) AS d
FROM (SELECT '192.168.1.4' AS ip FROM t1) Y

-- ------------------------------------------------------------------------

SELECT e.ename,e.sal,
(SELECT SUM(d.sal) FROM emp d 
WHERE d.empno<=e.empno) AS running_total
FROM emp e
ORDER BY 3

-- ----------------------------------------------

SELECT e.ename,e.sal,
(SELECT CAST(EXP(SUM(LN(d.sal))) AS UNSIGNED) FROM emp d
WHERE d.empno<=e.empno AND d.deptno = e.deptno
) AS total_prod
FROM emp e
WHERE e.deptno = 10
ORDER BY 3

-- ----------------------------------------------
SELECT * FROM emp WHERE deptno=30 ORDER BY sal

SELECT e.empno,e.ename,e.sal,
( SELECT CASE WHEN e.empno=MIN(d.empno) THEN SUM(d.sal)
	 /* 此处不能单独写sum(-d.sal),因为这表示对整列求和，把第一行也算进去了，并且都算成了负值，可第一行应该是正值。
	    因此需要把多减去的第一行的值补回来，因为本来应该加但是却减了第一行的值，所以里外里差了2倍，所以要乘以2.
	    (SELECT a.sal FROM emp a WHERE a.empno=d.empno LIMIT 1)*2 */
	 ELSE SUM(-d.sal)+(SELECT a.sal FROM emp a WHERE a.empno=d.empno LIMIT 1)*2
	 END
  FROM emp d
  WHERE e.deptno = d.deptno AND
  d.empno <= e.empno 
) AS rnk
FROM emp e
WHERE e.deptno=10

-- ----------------------------------------------------------------------------------------------------------------

SELECT sal FROM emp a
WHERE a.deptno=20
GROUP BY sal
HAVING COUNT(*) >= ALL(SELECT COUNT(*)  FROM emp b 
WHERE b.deptno=20 GROUP BY sal )
-- ---------------------------------------------------------------------------
/* 需求描述：按工资列排升序，如果总行数是奇数，选取中间一行的工资值，就是中间值
             如果总行数是偶数行，选取中间两行的工资值求平均值，作为中间值。
*/
-- 书里的答案，具体算法不是太理解---------------------------------------------
SELECT AVG(sal)
FROM (
SELECT e.sal
FROM emp e,emp d
WHERE e.deptno=d.deptno
AND e.deptno=20
GROUP BY e.sal
HAVING SUM(CASE WHEN e.sal = d.sal THEN 1 ELSE 0 END) >= ABS(SUM(SIGN(e.sal-d.sal)))
) m

-- 自己的答案，符合需求，根据需求的描述一步一步实现------------------------------

-- 4.外面再包一层，对上一步返回的两个值求平均值，就是要求的中间值。
--   因为avg函数只能对列操作，不能对行操作。因此使用两列相加/2计算平均值。
SELECT (c.n1+c.n2)/2 AS sal
FROM
     -- 3.外面再包一层，利用substring_index函数来截取上一步返回的字符串，因为最多只有一个逗号，
     --   所以一次截取逗号左边的值，一次截取逗号右边的值，分别放在两个字段里。如果字符串只有一个值也没关系，
     --   截取两次的值完全相同，也是分别放在两个字段里。并在substring_index函数外面包一层convert函数，
     --   把字符串转成unsigned。此步骤只返回一条记录，有两列，分别存放着数值。
( SELECT CONVERT(SUBSTRING_INDEX(b.sal_str,',',1),UNSIGNED) AS n1,
         CONVERT(SUBSTRING_INDEX(b.sal_str,',',-1),UNSIGNED) AS n2
  FROM 
     -- 2.外层根据返回的总行数判断是奇数还是偶数，利用case语句和substring_index函数来截取字符串里的一个或两个值。
     --   偶数截取2个，奇数截取一个。此步骤返回一个字符串，里面可能包含一个或两个值。但可以确定字符串里最多含有一个逗号
   ( SELECT CASE WHEN a.cnt%2=0 THEN SUBSTRING_INDEX(SUBSTRING_INDEX(sals,',',a.cnt/2+1),',',-2)
            ELSE SUBSTRING_INDEX(SUBSTRING_INDEX(sals,',',a.cnt/2),',',-1)
            END AS sal_str
     FROM  
         -- 1.首先使用group_concat()把数据那列排升序、用逗号分隔，把多行的值放在一行里，group by某字段。
         --   并且用count(*)求出一共有多少行。此步骤只返回一行记录：一个包含所有值的字符串和一个总行数
        (SELECT GROUP_CONCAT(sal ORDER BY sal SEPARATOR',') AS sals,COUNT(*) AS cnt FROM emp WHERE deptno=20 GROUP BY deptno) a
    ) b
) c

-- --------------------------------------------------------------------------------------------------
-- 求deptno=10的工资占工资总和的百分比

SELECT a.sal_10/SUM(e.sal)*100 AS pct
FROM (SELECT SUM(sal) AS sal_10 FROM emp WHERE deptno=10) a,emp e

-- --------------------------------------------------------------------------------------

SELECT AVG(COALESCE(comm,0)) FROM emp WHERE deptno=30
-- ------------------------------------------------------------

SELECT CASE WHEN a.trx='PY' THEN 'PAYMENT'
            ELSE 'PURCHASE'
            END AS trx_type,
       a.amt,
       ( SELECT SUM(CASE WHEN b.trx='PY' THEN -b.amt
                         ELSE b.amt 
                         END
                    )
         FROM v3 b
         WHERE b.id <= a.id
       ) AS balence
FROM v3 a

-- -------------------------------------------------------------
-- 加减年月日
SELECT empno,ename,hiredate,
       hiredate - INTERVAL 5 DAY AS 聘用前5天,
       HIREDATE + INTERVAL 5 DAY AS 聘用后5天,
       HIREDATE - INTERVAL 5 MONTH AS 聘用前5个月,
       HIREDATE + INTERVAL 5 MONTH AS 聘用后5个月,
       HIREDATE - INTERVAL 5 YEAR AS 聘用前5年,
       hiredate + INTERVAL 5 YEAR AS 聘用后5年      
FROM emp
WHERE deptno=10

-- ---------------------------------------------------------------
-- 计算两个日期之间相差的天数
SELECT ename,hiredate FROM emp WHERE ename IN ('allen','ward')

SELECT DATEDIFF(ward_hd,allen_hd) AS 相差天数
FROM (SELECT HIREDATE AS allen_hd FROM emp WHERE ename='allen') X,
     (SELECT HIREDATE AS ward_hd FROM emp WHERE ename='ward') Y
     
-- ----------------------------------------------------------------

SELECT DATE_FORMAT(hiredate,'%a')
FROM emp

-- ----------------------------------------------------------------

-- 计算两个日期之间有多少个工作日
SELECT ename,hiredate FROM emp WHERE ename IN ('BLAKE','jones')

SELECT SUM(CASE WHEN DATE_FORMAT(DATE_ADD(jones_hd,INTERVAL t500.`ID`-1 DAY),'%a') NOT IN ('Sat','Sun') THEN 1 
                ELSE 0
                END) AS 相差工作日
FROM(
SELECT MAX(CASE WHEN ename='BLAKE' THEN HIREDATE END) AS 'BLAKE_hd',
       MAX(CASE WHEN ename='JONES' THEN HIREDATE END) AS 'JONES_hd'
FROM emp
WHERE ename IN ('BLAKE','JONES')
) X, T500
WHERE t500.`ID`<=DATEDIFF(blake_hd,jones_hd)+1

-- -----------------------------------------------------------------
-- 计算最大和最小聘用日期之间的月数和换算成的年数
SELECT months AS 相差月数, months/12 AS 相差年数
FROM(
SELECT (YEAR(max_hd)-YEAR(min_hd))*12 + (MONTH(max_hd)-MONTH(min_hd)) AS months
FROM(
SELECT MAX(HIREDATE) AS max_hd, MIN(HIREDATE) AS min_hd
FROM emp
) X
) Y

-- -------------------------------------------------------------------
-- 计算两个日期相差的秒、分、小时数
SELECT DATEDIFF(ward_hd,allen_hd) AS days,
       DATEDIFF(ward_hd,allen_hd)*24 AS hours,
       DATEDIFF(ward_hd,allen_hd)*24*60 AS minutes,
       DATEDIFF(ward_hd,allen_hd)*24*60*60 AS seconds
FROM(
SELECT MAX(CASE WHEN ename='allen' THEN HIREDATE END) AS allen_hd,
       MAX(CASE WHEN ename='ward' THEN HIREDATE END) AS ward_hd
FROM emp
) X

-- --------------------------------------------------------------------
-- 计算一年中每个日期（星期几）出现的次数
SELECT z.wkday,COUNT(*)
FROM(
  SELECT DATE_FORMAT(DATE_ADD(startdate,INTERVAL t500.`ID`-1 DAY),'%W') AS wkday,
         y.startdate,
         t500.`ID`
  FROM(
	SELECT startdate,DATEDIFF(enddate,startdate) AS daycnts
	FROM ( SELECT CONCAT(YEAR(CURRENT_DATE),'-01-01') AS startdate,
		      CONCAT(YEAR(CURRENT_DATE),'-12-31') AS enddate
	     ) X
       ) Y,T500
  WHERE t500.`ID`<= y.daycnts+1
) z 
GROUP BY z.wkday

-- select datediff('2018-01-01','2018-12-31')

-- -------------------------------------------------------------------------------
-- 计算当前记录和下一条记录的日期相差几天
SELECT x.*,DATEDIFF(x.next_hd,x.hiredate) AS diff
FROM(
SELECT e.empno,e.ename,e.hiredate,
(SELECT MIN(d.`HIREDATE`)
FROM emp d
WHERE d.HIREDATE > e.hiredate
) AS next_hd
FROM emp e
WHERE e.deptno=10
) X

-- -------------------------------------------------------------------------------
-- 判断一年是否是闰年

SELECT LAST_DAY(CONCAT(YEAR(CURRENT_DATE),'-02-01')) AS dy
-- -------------------------------------------------------------------------------
-- 求当前年有多少天

SELECT DATEDIFF(x.nex_year,x.cur_year) AS daysofyear
FROM(
SELECT CONCAT(YEAR(CURRENT_DATE),'-01-01') AS cur_year,
       DATE_ADD(CONCAT(YEAR(CURRENT_DATE),'-01-01'),INTERVAL 1 YEAR) AS nex_year
) X
-- --------------------------------------------------------------------------------
-- 提取日期中的各个部分：年、月、日、时、分、秒

SELECT DATE_FORMAT(CURRENT_TIMESTAMP,'%Y') AS `year`,
       DATE_FORMAT(CURRENT_TIMESTAMP,'%m') AS `month`,
       DATE_FORMAT(CURRENT_TIMESTAMP,'%d') AS `day`,
       DATE_FORMAT(CURRENT_TIMESTAMP,'%H') AS `hour`,
       DATE_FORMAT(CURRENT_TIMESTAMP,'%i') AS `minute`,
       DATE_FORMAT(CURRENT_TIMESTAMP,'%s') AS `second`
FROM t1

-- --------------------------------------------------------------------------------
-- 获取当月第一天和最后一天

SELECT DATE_ADD(CURRENT_DATE,INTERVAL -DAY(CURRENT_DATE)+1 DAY) AS firstday,
       LAST_DAY(CURRENT_DATE) AS lastday
FROM t1
-- select currentdate-day(current_date)
-- --------------------------------------------------------------------------------
-- 求一年所有的星期五

SELECT all_dates AS All_Fridays
FROM(
SELECT DATE_ADD(x.y_firstday,INTERVAL t500.`ID`-1 DAY) AS all_dates
FROM(
SELECT CONCAT(YEAR(CURRENT_DATE),'-01-01') AS y_firstday,
       CONCAT(YEAR(CURRENT_DATE),'-12-31') AS y_lastday      
FROM t1
) X,t500
WHERE t500.`ID`<= DATEDIFF(y_lastday,y_firstday)+1
) Y
WHERE DATE_FORMAT(all_dates,'%w')=5

-- ----------------------------------------------------------------------------------
-- 求本月的第一个和最后一个星期一的日期
SELECT MIN(all_dates) AS first_monday,
       MAX(all_dates) AS last_monday
FROM(
SELECT DATE_ADD(startday,INTERVAL t500.`ID`-1 DAY) AS all_dates
FROM(
SELECT DATE_ADD(DATE_ADD(LAST_DAY(CURRENT_DATE),INTERVAL 1 DAY),INTERVAL -1 MONTH) AS startday,
       LAST_DAY(CURRENT_DATE) AS lastday
FROM t1
) X,t500
WHERE t500.`ID`<=DATEDIFF(lastday,startday)+1
) Y
WHERE DATE_FORMAT(all_dates,'%w')=1

-- ----------------------------------------------------------------------------------
-- 创建当月的日历(5行7列，周一开始)

SELECT MAX(CASE dw WHEN 1 THEN dm END) AS Mo,
       MAX(CASE dw WHEN 2 THEN dm END) AS Tu,
       MAX(CASE dw WHEN 3 THEN dm END) AS We,
       MAX(CASE dw WHEN 4 THEN dm END) AS Th,
       MAX(CASE dw WHEN 5 THEN dm END) AS Fr,
       MAX(CASE dw WHEN 6 THEN dm END) AS Sa,
       MAX(CASE dw WHEN 0 THEN dm END) AS Su
FROM(
SELECT DATE_FORMAT(all_dates,'%d') AS dm, -- 得到日期的日
       DATE_FORMAT(all_dates,'%w') AS dw, -- 得到日期是星期几
       DATE_FORMAT(all_dates,'%u') AS wk  -- 得到日期属于第几周
FROM(
/***********以下是求出当月所有日期的代码***************/
SELECT DATE_ADD(firstday,INTERVAL t500.`ID`-1 DAY) AS all_dates
FROM(
SELECT LAST_DAY(CURRENT_DATE) AS lastday,
       DATE_ADD(DATE_ADD(LAST_DAY(CURRENT_DATE),INTERVAL 1 DAY),INTERVAL -1 MONTH) AS firstday
FROM t1
) X,t500
WHERE t500.`ID`<=DATEDIFF(lastday,firstday)+1
/*******************************************************/
) Y
) z
GROUP BY wk -- 按周分组
ORDER BY wk -- 按周排序

-- -------------------------------------------------------------------------
-- 显示一年中每个季度的开始日期和结束日期

SELECT id AS Q, 
       DATE_ADD(dy,INTERVAL 3*(id-1) MONTH) AS q_start,  -- 每季度开始日期，id-1是确保一季度的第一天包含在内
       DATE_ADD(DATE_ADD(dy,INTERVAL 3*(id) MONTH),INTERVAL -1 DAY) AS q_end  -- 每季度开始日期减去一天，得到上个季度的最后一天
FROM(
SELECT id,
       DATE_ADD(CURRENT_DATE,INTERVAL -DAYOFYEAR(CURRENT_DATE)+1 DAY) AS dy
       
FROM t500
WHERE t500.`ID`<=4
) X
-- ------------------------------------------------------------------------------
-- 确定给定季度的开始和结束日期
SELECT DATE_ADD(DATE_ADD(q_end,INTERVAL +1 DAY),INTERVAL -3 MONTH) AS q_start,
       q_end
FROM(
SELECT DATE_FORMAT(LAST_DAY(STR_TO_DATE(CONCAT(yr,Q),'%Y%m')),'%Y-%m-%d') AS q_end
FROM(
SELECT SUBSTR(yrq,1,4) AS yr, MOD(yrq,10)*3 AS Q
FROM(
SELECT 20181 AS yrq FROM t1 UNION ALL
SELECT 20182 AS yrq FROM t1 UNION ALL
SELECT 20183 AS yrq FROM t1 UNION ALL
SELECT 20184 AS yrq FROM t1 
) X
) Y
) z

-- ----------------------------------------------------------------------------
-- 求1980-1983年之间每个月聘用的员工数
-- 如果不显示没有聘用员工的月份
-- select sum(emps)
-- from(
SELECT CONCAT(YEAR(HIREDATE),'-',MONTH(hiredate)) AS mth,COUNT(*) AS emps
FROM emp
GROUP BY CONCAT(YEAR(HIREDATE),MONTH(hiredate))
ORDER BY YEAR(HIREDATE),MONTH(HIREDATE)
-- ) x

SELECT x.mth, 
       (CASE WHEN y.emps IS NULL THEN 0 
             ELSE y.emps
             END) AS hirecnt  -- 处理以下NULL值，有值的显示值，为NULL的显示0
FROM
(-- 利用基干表和已知的开始日期，得到1980-1983年所有的月份的第一天，代表此月份
	SELECT DATE_ADD(STR_TO_DATE('19800101','%Y%m%d'),INTERVAL t500.`ID`-1 MONTH) AS mth
	FROM t500
	WHERE t500.`ID`<=48
) X 
LEFT JOIN -- 月份表与每个月雇佣人数的表外连接，在月份表里能匹配的月份就有雇佣人数的值，不能匹配的就是NULL
(-- 查询所有员工的hiredate，把日期都处理成当月的1号，然后group by，count(*)得到每个月雇佣了几个人
	SELECT DATE_ADD(HIREDATE,INTERVAL -DAY(hiredate)+1 DAY) AS hiremonth,COUNT(*) AS emps
	FROM emp
	GROUP BY DATE_ADD(HIREDATE,INTERVAL -DAY(hiredate)+1 DAY)
) Y
ON x.mth = y.hiremonth

-- select ename,HIREDATE from emp order by HIREDATE

-- ----------------------------------------------------------------------------------------------
-- 查询所有2月、12月或星期二雇佣的员工
SELECT *
FROM emp
WHERE MONTHNAME(HIREDATE) IN ('February','December')
OR DAYNAME(HIREDATE) = 'Tuesday'

-- -------------------------------------------------------------------
-- 查询所有在同一个月份并且星期几也相同雇佣的员工

SELECT a.ename,a.hiredate,a.empno,b.empno,b.ename,b.hiredate  
FROM emp a,emp b
WHERE (DAYNAME(a.hiredate),MONTHNAME(a.hiredate))=
      (DAYNAME(b.hiredate),MONTHNAME(b.hiredate))
  AND a.empno < b.empno
ORDER BY a.ename
-- --------------------------------------------------------------------
-- 查找在老工程结束之前就开始新工程的员工

SELECT a.ename,a.proj_id,a.proj_start,b.proj_start,b.proj_end,b.proj_id
FROM emp_project a, emp_project b
WHERE a.empno = b.empno
  AND b.proj_start <= a.proj_start AND a.proj_start<= b.proj_end
  AND a.proj_id <> b.proj_id
-- ----------------------------------------------------------------------
-- 查找连续的工程

SELECT a.proj_id,
       a.proj_start AS a_start,
       a.proj_end AS a_end
FROM v4 a,v4 b
WHERE a.proj_end = b.proj_start
ORDER BY a_start

-- -----------------------------------------------------------------------
-- 求同部门的员工工资的差，按照聘用日期早的和较晚的顺序对比，
-- 部门最后一个雇佣的员工没有比较对象，差值是N/A
SELECT deptno,ename,hiredate,sal,
      (CASE WHEN next_sal IS NULL THEN 'N/A'
            ELSE sal-next_sal
            END) AS diff    
FROM(     
    SELECT e.deptno,e.ename,e.hiredate,e.sal,
    (SELECT MIN(sal) FROM emp d
     WHERE d.deptno=e.deptno AND
     d.hiredate = ( SELECT MIN(b.hiredate)
                    FROM emp b
                    WHERE e.deptno=b.deptno AND e.hiredate < b.hiredate
                  )
         
    ) AS next_sal 
    FROM emp e
    ORDER BY 1
) X
ORDER BY deptno,HIREDATE
-- --------------------------------------------------------------------
-- 查询日期连续的工程组的开始日期和结束日期
SELECT proj_grp,
MIN(proj_start) AS proj_start,
MAX(proj_end) AS proj_end
FROM(
SELECT a.proj_id,a.proj_start,a.proj_end,
(SELECT SUM(b.flag)
 FROM v5 b
 WHERE b.proj_id <= a.proj_id) AS proj_grp
FROM v5 a
) X
GROUP BY proj_grp
-- ----------------------------------------------------------
-- 查询1980年起10年中每年雇佣的员工数
SELECT y.yr,
(CASE WHEN x.cnt IS NULL THEN 0 ELSE x.cnt END) AS CNT
FROM(
SELECT 1980+t10.`id`-1 AS yr
FROM t10) Y LEFT JOIN
(
SELECT EXTRACT(YEAR FROM hiredate) AS yr,COUNT(*) AS cnt
FROM emp
GROUP BY yr
) X
ON y.yr = x.yr
-- ---------------------------------------------------------
-- 显示工资排在6-10位高的5行

SELECT ename,sal 
FROM emp 
ORDER BY sal DESC LIMIT 5 OFFSET 5
-- ---------------------------------------------------------
-- 跳过表中的n行，隔行选取姓名

SELECT ename,x.rn
FROM(
SELECT b.ename,
(
     SELECT COUNT(*)
     FROM emp a
     WHERE a.empno <= b.empno
) AS rn
FROM emp b
) X
WHERE MOD(x.rn,2)=1
ORDER BY x.rn
-- --------------------------------------------------------------
-- 查询部门是10或20的员工和部门信息，以及30和40的部门信息（不要员工信息）

SELECT d.deptno,e.ename,d.dname,d.loc
FROM dept d LEFT JOIN emp e
ON(d.deptno=e.deptno AND (e.deptno=10 OR e.deptno=20))
ORDER BY d.deptno
-- ------------------------------------------------------------
-- 找出值是互换的行，并只保留一个结果

SELECT DISTINCT a.*
FROM v6 a,v6 b
WHERE a.test1=b.test2
AND a.test2=b.test1
AND a.test1<=a.test2
-- --------------------------------------------------------
-- 查询工资等级最高的5档的员工姓名和工资
SELECT ename,sal,x.rnk
FROM(
SELECT a.ename,a.sal,
(
SELECT COUNT(DISTINCT sal)
FROM emp b
WHERE a.sal<=b.sal
) AS rnk
FROM emp a
) X
WHERE x.rnk<=5
ORDER BY x.rnk
-- ----------------------------------------------------------
-- 找出emp表中具有最高和最低工资的员工

SELECT empno,ename,deptno,sal
FROM emp
WHERE sal IN ((SELECT MIN(sal) FROM emp ),
              (SELECT MAX(sal) FROM emp))
-- ------------------------------------------------------------
-- 找出工资比紧随其后入职的员工低的员工，跨部门的

SELECT ename,sal,next_sal
FROM(
SELECT a.ename,a.sal,
(SELECT MIN(b.sal)
 FROM emp b
 WHERE b.hiredate = (SELECT MIN(c.hiredate)
                      FROM emp c
                      WHERE c.hiredate > a.hiredate)
) AS next_sal
FROM emp a
) X
WHERE sal < next_sal
-- --------------------------------------------------------------
-- 给emp表中的工资分档

SELECT a.sal,
(SELECT COUNT(DISTINCT b.sal)
 FROM emp b
 WHERE b.sal<=a.sal) AS rnk
FROM emp a
ORDER BY rnk
-- ----------------------------------------------------------------
-- 在emp表里查找不同的职位，不能有重复
SELECT DISTINCT job
FROM emp
-- ----------------------------------------------------
-- 列出所有部门的所有员工的信息，以及每个部门最新聘用的员工的工资
SELECT a.deptno,a.ename,a.sal,a.hiredate,
(SELECT b.sal
FROM emp b
WHERE b.deptno = a.deptno
ORDER BY b.hiredate DESC LIMIT 1) AS latest_sal
FROM emp a  
ORDER BY deptno ASC,hiredate DESC
-- --------------------------------------------------------
-- 为每个订单记录再生成2行，额外再增加两列，一列存放核对日期，一列存放出货日期

SELECT id,order_date,process_date,
(CASE WHEN rnum>=2 THEN DATE_ADD(process_date,INTERVAL 1 DAY) END) AS verified,
(CASE WHEN rnum=3 THEN DATE_ADD(process_date,INTERVAL 2 DAY) END) AS shipped
FROM(
SELECT odr.*,'' AS verified,'' AS shipped,x.id AS rnum
-- ,date_add(process_date,interval 1 day) as verified,
-- date_add(process_date,interval 2 day) as shipped
FROM
(SELECT id
FROM odr
) X,odr
) Y 

-- ----------------------------------------------------------------------
-- 查询每个部门员工的数量，将每个部门放在不同字段，结果显示在一行

SELECT SUM(CASE WHEN deptno=10 THEN 1 ELSE 0 END) AS deptno_10,
       SUM(CASE WHEN deptno=20 THEN 1 ELSE 0 END) AS deptno_20,
       SUM(CASE WHEN deptno=30 THEN 1 ELSE 0 END) AS deptno_30
FROM emp

-- ----------------------------------------------------------------------
-- 查询每个员工姓名以及他们的job，要求每个job作为列，每列下面列出员工姓名

SELECT MAX(CASE WHEN job='CLERK' THEN ename ELSE NULL END) AS clerks,
       MAX(CASE WHEN job='ANALYST' THEN ename ELSE NULL END) AS analysts,
       MAX(CASE WHEN job='MANAGER' THEN ename ELSE NULL END) AS mgrs,
       MAX(CASE WHEN job='PRESIDENT' THEN ename ELSE NULL END) AS prez,
       MAX(CASE WHEN job='SALESMAN' THEN ename ELSE NULL END) AS sales
FROM(
     SELECT ename,job,
     (SELECT COUNT(*) FROM emp a WHERE a.`JOB`=e.job AND a.`EMPNO`<=e.empno) AS rnk
     FROM emp e
) X
GROUP BY rnk
-- --------------------------------------------------------------------------
-- 把第一节的结果集再转成多行形式

SELECT dept.`DEPTNO`,
       CASE dept.deptno WHEN 10 THEN x.deptno_10
       WHEN 20 THEN x.deptno_20
       WHEN 30 THEN x.deptno_30
       END AS counts_by_dept 
FROM
(SELECT SUM(CASE WHEN deptno=10 THEN 1 ELSE 0 END) AS deptno_10,
       SUM(CASE WHEN deptno=20 THEN 1 ELSE 0 END) AS deptno_20,
       SUM(CASE WHEN deptno=30 THEN 1 ELSE 0 END) AS deptno_30
FROM emp) X,
(SELECT deptno FROM dept WHERE deptno<=30) dept
-- -------------------------------------------------------------------
-- 返回deptno 10中所有员工的ename、job、sal，使它们显示在一列，每个员工信息之间有一个空行
SELECT ( CASE t10.`id` WHEN 1 THEN x.ename
                       WHEN 2 THEN x.job
                       WHEN 3 THEN x.sal
                       WHEN 4 THEN NULL
                       END
        ) AS emps
FROM
(
SELECT a.ename,a.job,a.sal,
(SELECT COUNT(*) FROM emp b
 WHERE a.deptno=b.deptno AND
       a.empno>=b.empno) AS rnk
FROM emp a
WHERE a.deptno=10
) X,t10
WHERE t10.`id`<=4
ORDER BY x.rnk,t10.`id`
-- -------------------------------------------------
-- 查询各部门的所有员工姓名和部门编号，并且部门编号只显示1次

SELECT (CASE rnk WHEN 1 THEN deptno
           ELSE NULL END ) AS deptno,
        ename 
FROM(
SELECT a.ename,a.deptno,a.deptno AS dno,
(SELECT COUNT(*) FROM emp b
 WHERE a.deptno=b.deptno 
   AND a.empno>=b.empno) AS rnk
FROM emp a
) X
ORDER BY x.dno,x.rnk
-- -----------------------------------------------------
-- 计算各个部门的总工资差

SELECT (d20_sal-d10_sal) AS d20_10diff,
       (d20_sal-d30_sal) AS d20_30diff 
FROM(
SELECT SUM(CASE deptno WHEN 10 THEN sal END) AS d10_sal,
       SUM(CASE deptno WHEN 20 THEN sal END) AS d20_sal,
       SUM(CASE deptno WHEN 30 THEN sal END) AS d30_sal
FROM emp
) X
-- ------------------------------------------------------
-- 把每5个员工分成一组，它们具有相同的组编号
SELECT CEIL(x.rnk/5) AS grp,x.ename,x.empno
FROM(
SELECT a.empno,a.ename,
(SELECT COUNT(*)
FROM emp b
WHERE a.empno>=b.empno) AS rnk
FROM emp a
) X
 
-- --------------------------------------------------------
-- 把所有员工分成4个桶

SELECT a.ename,a.empno,COUNT(*),MOD(COUNT(*),4)+1 AS grp
FROM emp a,emp b
WHERE a.empno>=b.empno
GROUP BY a.empno,a.ename
ORDER BY 4,3
-- --------------------------------------------------------
-- 用一个星号表示一个员工，显示每个部门的员工数

SELECT deptno,RPAD('*',COUNT(*),'*') AS cnt
FROM emp
GROUP BY deptno
-- ---------------------------------------------------
-- 用每列表示一个部门，每个部门的员工数量用星号表示

SELECT MAX(dept_10) AS d10,
       MAX(dept_20) AS d20,
       MAX(dept_30) AS d30
FROM(
SELECT CASE a.deptno WHEN 10 THEN '*' ELSE NULL END AS dept_10,
       CASE a.deptno WHEN 20 THEN '*' ELSE NULL END AS dept_20,
       CASE a.deptno WHEN 30 THEN '*' ELSE NULL END AS dept_30,
(SELECT COUNT(*)
FROM emp b
WHERE a.empno>=b.empno AND 
      a.deptno=b.deptno) AS rnk
FROM emp a
ORDER BY deptno
) X
GROUP BY x.rnk
ORDER BY 1,2,3
-- -----------------------------------------------------------------
-- 查找每个部门工资最高和最低的员工，以及每种工作中最高和最低工资的员工

SELECT deptno,ename,job,sal,
      (CASE WHEN sal=max_by_dept THEN 'TOP SAL IN DEPT'
            WHEN sal=min_by_dept THEN 'LOW SAL IN DEPT'
            END) AS DEPT_STATUS,
       (CASE WHEN sal=max_by_job THEN 'TOP SAL IN JOB'
             WHEN sal=min_by_job THEN 'LOW SAL IN JOB'
             END) AS JOB_STATUS       
FROM(
SELECT e.deptno,e.ename,e.job,e.sal,
       (SELECT MAX(sal) FROM emp d WHERE d.`DEPTNO`=e.deptno) AS max_by_dept, 
       (SELECT MIN(sal) FROM emp d WHERE d.`DEPTNO`=e.deptno) AS min_by_dept, 
       (SELECT MAX(sal) FROM emp d WHERE d.`JOB`=e.job) AS max_by_job, 
       (SELECT MIN(sal) FROM emp d WHERE d.`JOB`=e.job) AS min_by_job
FROM emp e
) X
WHERE sal IN (max_by_dept,min_by_dept,max_by_job,min_by_job)
ORDER BY deptno
-- -------------------------------------------------------------------
-- 统计emp表的各个job的工资总和，再统计所有job的工资总计
-- 不使用with rollup----------
SELECT job,SUM(sal) AS sal
FROM emp
GROUP BY job
UNION ALL
SELECT 'Total' AS job,SUM(sal)
FROM(
SELECT job,SUM(sal) AS sal
FROM emp
GROUP BY job
) X 
-- ---------------------------
SELECT COALESCE(job,'total') AS job,
       SUM(sal) AS sal
FROM emp
GROUP BY job WITH ROLLUP
-- ------------------------------------------------------------------
-- 列出按部门、按job、按部门的job的工资和，最后再加上所有员工的工资总和
SELECT deptno,job,'TOTAL BY DEPT AND JOB' AS category,SUM(sal) AS sal
FROM emp 
GROUP BY deptno,job 
UNION ALL
SELECT NULL,job,'TOTAL BY JOB' AS category,SUM(sal) AS sal
FROM emp 
GROUP BY job 
UNION ALL
SELECT deptno,NULL,
       CASE WHEN deptno IS NOT NULL THEN 'TOTAL BY DEPT'
            ELSE 'GRAND TOTAL FOR TABLE' END AS category,
       SUM(sal) AS sal
FROM emp 
GROUP BY deptno WITH ROLLUP
-- ----------------------------------------------------------
-- 将每个job作为一列，给每个员工所属的job列标记为1，其他列标记为0

SELECT ename,
       CASE job WHEN 'clerk' THEN 1 ELSE 0 END AS is_clerk,
       CASE job WHEN 'salesman' THEN 1 ELSE 0 END AS is_sales,
       CASE job WHEN 'manager' THEN 1 ELSE 0 END AS is_mgr,
       CASE job WHEN 'analyst' THEN 1 ELSE 0 END AS is_analyst,
       CASE job WHEN 'president' THEN 1 ELSE 0 END AS is_prez
FROM emp
ORDER BY 2,3,4,5,6
-- ------------------------------------------------------------
-- 前3列按部门列出员工姓名，后3列按job列出员工姓名
SELECT CASE deptno WHEN 10 THEN ename ELSE NULL END AS d10, 
       CASE deptno WHEN 20 THEN ename ELSE NULL END AS d20,
       CASE deptno WHEN 30 THEN ename ELSE NULL END AS d30,  
       CASE job WHEN 'clerk' THEN ename ELSE NULL END AS clerk,
       CASE job WHEN 'salesman' THEN ename ELSE NULL END AS sales,
       CASE job WHEN 'manager' THEN ename ELSE NULL END AS mgr,
       CASE job WHEN 'analyst' THEN ename ELSE NULL END AS analyst,
       CASE job WHEN 'president' THEN ename ELSE NULL END AS prez
FROM emp
-- -----------------------------------------------------------------
-- 求每5秒的总事务数，列出开始时间和结束时间

SELECT grp,MIN(trx_date) AS trx_start,MAX(trx_date) AS trx_end,SUM(trx_cnt) AS Total
FROM(
SELECT CEIL(trx_id/5) AS grp,trx_id
FROM trx_log
) X,trx_log t
WHERE t.trx_id=x.trx_id
GROUP BY grp
-- -----------------------------------------------------------------------
-- 列出每个员工的名字，部门，该部门的员工数，job，与他job相同的员工数，总员工数

SELECT ename,deptno,
       (SELECT COUNT(*) FROM emp d WHERE d.deptno=e.deptno) AS deptno_cnt,
       job,
       (SELECT COUNT(*) FROM emp d WHERE d.job=e.job) AS job_cnt,
       (SELECT COUNT(*) FROM emp) AS total
FROM emp e
ORDER BY 2,1,3,4,5
-- ------------------------------------------------------------------------
-- 每个员工计算与前90天内雇佣的员工的工资之和

SELECT hiredate,sal,
(SELECT SUM(sal) FROM emp d
 WHERE d.hiredate BETWEEN DATE_ADD(e.hiredate,INTERVAL -90 DAY) AND e.hiredate) AS spending_pattern
FROM emp e
ORDER BY HIREDATE,sal

-- ------------------------------------------------------------------------
-- 列出每个经理手下按部门统计的员工的总工资，以及同部门不同经理手下的员工工资和，最后对每个部门的工资和再求和
SELECT mgr,
       MAX(CASE deptno WHEN 10 THEN sal ELSE NULL END) AS dept10,
       MAX(CASE deptno WHEN 20 THEN sal ELSE NULL END) AS dept20,
       MAX(CASE deptno WHEN 30 THEN sal ELSE NULL END) AS dept30,
       MAX(CASE WHEN deptno IS NULL THEN sal ELSE NULL END) AS total
       
FROM(
-- 将如下表转置成行显示
SELECT deptno,mgr,SUM(sal) AS sal
FROM emp
WHERE mgr IS NOT NULL
GROUP BY deptno,mgr WITH ROLLUP
) X
GROUP BY mgr
ORDER BY total,mgr,2,3,4
-- -------------------------------------------------------------------------
-- 查询每个员工以及他的经理

SELECT CONCAT(a.ename,' works for ',b.ename) AS emps_and_mgrs
FROM emp a,emp b
WHERE a.mgr = b.empno

-- --------------------------------------------------------------------------
-- 查出员工的经理的经理
SELECT CONCAT(a.ename,'-->',b.ename,'-->',c.ename) AS leaf_branch_root
FROM emp a,emp b,emp c
WHERE a.ename = 'MILLER'
  AND a.mgr = b.empno
  AND b.mgr = c.empno
-- -------------------------------------------------------------------------
-- 列出每个员工及其下级员工，同一层级的员工显示多行，不同层级的显示多列

SELECT ename AS emp_tree FROM emp WHERE mgr IS NULL 
UNION
SELECT CONCAT(b.ename,'-->',a.ename) AS emp_tree FROM emp a,emp b
WHERE a.mgr=(SELECT empno FROM emp WHERE mgr IS NULL) AND b.empno=(SELECT empno FROM emp WHERE mgr IS NULL)
UNION
SELECT CONCAT(b.ename,'-->',a.ename,'-->',c.ename) AS emp_tree FROM emp a,emp b,emp c
WHERE a.mgr=(SELECT empno FROM emp WHERE mgr IS NULL) AND b.empno=(SELECT empno FROM emp WHERE mgr IS NULL)
      AND c.mgr=a.empno
UNION
SELECT CONCAT(b.ename,'-->',a.ename,'-->',c.ename,'-->',d.ename) AS emp_tree FROM emp a,emp b,emp c,emp d
WHERE a.mgr=(SELECT empno FROM emp WHERE mgr IS NULL) AND b.empno=(SELECT empno FROM emp WHERE mgr IS NULL)
      AND c.mgr=a.empno AND d.mgr=c.empno

-- --------------------------------------------------------------------------------
-- 找到jones的所有下属，以及下属的下属
CREATE VIEW root AS
SELECT ename,empno,mgr
FROM emp 
WHERE ename='jones'

CREATE VIEW branch AS
SELECT ename,empno,mgr
FROM emp
WHERE mgr=(SELECT empno FROM root)

CREATE VIEW leaf AS
SELECT ename,empno,mgr
FROM emp
WHERE mgr IN (SELECT empno FROM branch)

SELECT ename FROM root
UNION
SELECT ename FROM branch
UNION
SELECT ename FROM leaf
-- -------------------------------------------------------
-- 用数字1和0在leaf,branch,root列上标记出该员工属于哪种节点

SELECT ename,
       0  AS is_leaf,
       0  AS is_branch,
       COUNT(*) AS is_root
FROM emp
WHERE mgr IS NULL
UNION
SELECT ename,
       CASE WHEN cnt=1 THEN 1 ELSE 0 END AS is_leaf,
       CASE WHEN cnt>1 THEN 1 ELSE 0 END AS is_branch,
       0 AS is_root
FROM(
SELECT empno,COUNT(*) AS cnt
FROM(
SELECT empno
FROM emp
WHERE mgr IS NOT NULL
UNION ALL
SELECT mgr
FROM emp
WHERE mgr IS NOT NULL AND mgr <> (SELECT empno FROM emp WHERE mgr IS NULL)
) X
GROUP BY empno
) Y,emp e
WHERE y.empno=e.empno
ORDER BY 2,3,1