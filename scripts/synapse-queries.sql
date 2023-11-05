-- Count the number of athletes from each country:
select NOC, count(*) as TotalAthletes
from athletes
group by NOC
order by TotalAthletes desc;

-- Calculate the total medals won by each country:
select
Team_NOC,
sum(Gold) Total_Gold,
sum(Silver) Total_Silver,
sum(Bronze) Total_Bronze
from medals
group by Team_NOC
order by Total_Gold desc;

-- Calculate the average number of entries by gender for each discipline
select Discipline,
avg(Female) Avg_Female,
avg(Male) Avg_Male
from entriesgender
group by Discipline;
