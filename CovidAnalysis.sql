select * 
from PortfolioProject..CovidDeaths
order by 3,4

-- Select data to use

Select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- Looking at total cases vs total deaths
-- shows likelihood of dying if contracted covid in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as death_percentage
from PortfolioProject..CovidDeaths
where Location = 'United States'
and continent is not null
order by 1,2

-- Looking at the total cases vs population
-- shows what percentage of population got covid
Select Location, date, total_cases, Population, (total_cases/Population) * 100 as case_percentage
from PortfolioProject..CovidDeaths
where Location = 'United States'
and continent is not null
order by 1,2

-- Looking at the countries with highest infection rate compared to population
Select Location, MAX(total_cases) as highest_infection_count, Population, MAX((total_cases/Population)) * 100 as infection_percentage
from PortfolioProject..CovidDeaths
where continent is not null
group by Location, Population
order by infection_percentage desc

-- Looking at countries with highest death count per population
Select Location, MAX(cast(Total_deaths as int)) as total_death_count
from PortfolioProject..CovidDeaths
where continent is not null
group by Location
order by total_death_count desc

-- by continent
Select continent, MAX(cast(Total_deaths as int)) as total_death_count
from PortfolioProject..CovidDeaths
where continent is not null
and iso_code not in 
(
	'OWID_LIC',
	'OWID_HIC',
	'OWID_LMC',
	'OWID_UMC'
)
group by continent
order by total_death_count desc

-- by income
Select location, MAX(cast(Total_deaths as int)) as total_death_count
from PortfolioProject..CovidDeaths
where continent is null
and iso_code in 
(
	'OWID_LIC',
	'OWID_HIC',
	'OWID_LMC',
	'OWID_UMC'
)
group by location
order by total_death_count desc

-- globally
select 
	SUM(new_cases) as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as death_percentage
from PortfolioProject..CovidDeaths
-- where Location = 'United States'
where continent is not null
--group by date
order by 1,2


-- Looking at total population vs new vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (partition by dea.location order by dea.location, dea.date) as rolling_vaccinations
from PortfolioProject..CovidVaccinations vac
join PortfolioProject..CovidDeaths dea
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE to see percentage of population vaccinated

with PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccinations)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (partition by dea.location order by dea.location, dea.date) as rolling_vaccinations
from PortfolioProject..CovidVaccinations vac
join PortfolioProject..CovidDeaths dea
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

select *, (rolling_vaccinations/population) * 100 as vacc_pop_percentage
from PopvsVac 

-- Using Temp table to see percentage of population vaccinated

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (partition by dea.location order by dea.location, dea.date) as rolling_vaccinations
from PortfolioProject..CovidVaccinations vac
join PortfolioProject..CovidDeaths dea
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null

select *, (rolling_vaccinations/population) * 100 as vacc_pop_percentage
from #PercentPopulationVaccinated 

-- create view to store data for later visualizations
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (partition by dea.location order by dea.location, dea.date) as rolling_vaccinations
from PortfolioProject..CovidVaccinations vac
join PortfolioProject..CovidDeaths dea
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null

select * from PercentPopulationVaccinated
order by 2, 3


-- tableau queries

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as death_percentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2

Select location, SUM(cast(new_deaths as int)) as total_death_count
From PortfolioProject..CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
and iso_code not in 
(
	'OWID_LIC',
	'OWID_HIC',
	'OWID_LMC',
	'OWID_UMC'
)
Group by location
order by total_death_count desc

Select location, SUM(cast(new_deaths as int)) as total_death_count
From PortfolioProject..CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
and iso_code in 
(
	'OWID_LIC',
	'OWID_HIC',
	'OWID_LMC',
	'OWID_UMC'
)
Group by location
order by total_death_count desc

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as percent_pop_infected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by percent_pop_infected desc

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as percent_pop_infected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by percent_pop_infected desc