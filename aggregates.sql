select count(facid) from cd.facilities

select count(*) from cd.facilities where guestcost >= 10

select recommendedby,count(recommendedby) from cd.members where recommendedby is not null group by recommendedby order by recommendedby

select facid,sum(slots) from cd.bookings group by facid order by facid

select facid,sum(slots) from cd.bookings where to_char(starttime, 'YY-MM') = '12-09' group by facid order by sum(slots)

select facid,extract(month from starttime) as month,sum(slots) from cd.bookings where to_char(starttime, 'YY') = '12' group by facid,month order by facid,month

select count(distinct memid) from cd.bookings

select facid,sum(slots) from cd.bookings group by facid having sum(slots) > 1000 order by facid

select name,sum(b.slots * case
			when memid = 0 then guestcost
			else membercost
		end) as revenue
from cd.facilities f left join cd.bookings b on f.facid = b.facid 
group by f.facid 
order by revenue

select * from (select f.name,sum(b.slots * case
			when b.memid = 0 then f.guestcost
			else f.membercost
		end) as revenue
from cd.facilities f left join cd.bookings b on f.facid = b.facid 
group by f.facid
order by revenue) as t where t.revenue < 1000

select facid,sum(slots) from cd.bookings group by facid order by sum(slots) desc limit 1

select facid,extract(month from starttime) as month,sum(slots) 
from cd.bookings
where extract(year from starttime) = 2012
group by rollup(facid, month) 
order by facid,month

select f.facid,f.name,0.5*sum(b.slots)::decimal(10,1) as "Total Hours"
from cd.bookings b join cd.facilities f on b.facid = f.facid
group by f.facid
order by f.facid

select m.surname,m.firstname,m.memid,t.starttime from
(select memid,min(starttime) as starttime
from cd.bookings 
where starttime >= '2012-09-01'
group by memid 
order by memid) t
join cd.members m on t.memid = m.memid

select (select count(*) from cd.members) as count, firstname, surname
	from cd.members
order by joindate

select row_number() over(order by joindate) as row_number,firstname,surname from cd.members order by joindate

with t as (select facid,sum(slots) as total from cd.bookings group by facid)
select t.facid, total from t
where total in (select max(total) from t)


select firstname,surname,hours, rank() over(order by hours desc)
from cd.members m join (
  select memid,round(0.5*sum(slots), -1) as hours
from cd.bookings
group by memid) b
on m.memid = b.memid
order by rank, surname,firstname

select * from (
  select name,rank() over(order by revenue desc) from (
  select name,sum(b.slots * case
			when memid = 0 then guestcost
			else membercost
		end) as revenue
from cd.facilities f left join cd.bookings b on f.facid = b.facid 
group by f.facid) f
order by rank,name
  ) t
  where rank <= 3

select name, case 
when ntile = 1 then 'high' 
when ntile = 2 then 'average' 
when ntile = 3 then 'low' end revenue from (
  select name,ntile(3) over(order by revenue desc) from (
  select name,sum(b.slots * case
			when memid = 0 then guestcost
			else membercost
		end) as revenue
from cd.facilities f left join cd.bookings b on f.facid = b.facid 
group by f.facid) f
order by ntile,name) t

select name,initialoutlay / (avg - monthlymaintenance) months
from (
  select f.name,initialoutlay, monthlymaintenance, avg
from cd.facilities f join
(select name,avg(revenue) from (
  select name, extract(month from starttime) as month,sum(b.slots * case
			when memid = 0 then guestcost
			else membercost
		end) as revenue
from cd.facilities f left join cd.bookings b on f.facid = b.facid
  -- I just used 2012 as a hack to get the 3 full months of data
  where extract(year from starttime) = 2012
group by f.facid, month ) t
group by name) avg_income
on f.name = avg_income.name) data
order by name

select * from (select day,
avg(revenue) OVER(ORDER BY day ROWS BETWEEN 14 PRECEDING AND CURRENT ROW) as revenue 
from (
  select to_char(starttime, 'YYYY-MM-DD') as day,sum(b.slots * case
			when memid = 0 then guestcost
			else membercost
		end) as revenue
from cd.facilities f left join cd.bookings b on f.facid = b.facid
where starttime < '2012-09-01'
group by day
order by day) t) t2
where day >= '2012-08-01' 
