
 /*

 Data Exploration in sql queries

 */

--1
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast (new_deaths as int))/SUM(New_cases)*100 as DeathPercentage
-- whenever ncarchar using cast
From [Portfolio projects]..CovidDeaths
where continent is not null
order by 1,2 

--2
-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From [Portfolio projects]..CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

--3
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From [Portfolio projects]..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

-- 4.
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From [Portfolio projects]..CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc



Select * from [Portfolio projects]..CovidDeaths
order by 3,4;

--Select * from [Portfolio projects]..CovidVaccinations
--order by 3,4;

--Data Exploration
Select location,date,total_cases,new_cases,total_deaths,population
From [Portfolio projects]..CovidDeaths
where continent is not null
order by 1,2

--Looking at Total cases and Total Deaths
--Shows the likelihood of dying if you contract covid in your country
Select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
From [Portfolio projects]..CovidDeaths
Where location like '%india%' and  continent is not null
order by 1,2

--Looking at the total cases vs population
--Shows what percentage of population got Covid
Select location,date,population,total_cases,(total_cases/population)*100 as PercentPopulationInfected
From [Portfolio projects]..CovidDeaths
Where location like '%india%' and  continent is not null
order by 1,2

--Looking at countries with highest infection rate compared to population
Select location,population,Max(total_cases) as HighestInfectionCount,Max(total_cases/population)*100 as 
PercentPopulationInfected
From [Portfolio projects]..CovidDeaths
where continent is not null
--Where location like '%india%'
group by location,population
order by PercentPopulationInfected desc

--Showing Countries with Highest Death count per population 
--nvarchar255 total deaths  is an issue with the data type annd so we caste it as a numeric
--continent has asia and location has asia so we can add where continent is not null


Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From [Portfolio projects]..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc


--Lets break things down by continent
--Showing continents with highest death count per population
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From [Portfolio projects]..CovidDeaths
where continent is  not null
group by continent
order by TotalDeathCount desc

--Global numbers
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast (new_deaths as int))/SUM(New_cases)*100 as DeathPercentage
-- whenever ncarchar using cast
From [Portfolio projects]..CovidDeaths
where continent is not null
order by 1,2 

--Total Populations Vs Vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--,SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location)
,SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
From [Portfolio projects]..CovidDeaths dea
Join [Portfolio projects]..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE
WITH PopvsVac (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--,SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location)
,SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
From [Portfolio projects]..CovidDeaths dea
Join [Portfolio projects]..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null)
--order by 2,3 
Select * , (RollingPeopleVaccinated/Population)*100 
From PopVsVac

--TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--,SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location)
,SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
From [Portfolio projects]..CovidDeaths dea
Join [Portfolio projects]..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
Select * , (RollingPeopleVaccinated/Population)*100 
From #PercentPopulationVaccinated

--See and try to create many views 
-- Next is tableau public
-- creating View to store data for later vizualizations
--Create View
Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--,SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location)
,SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
From [Portfolio projects]..CovidDeaths dea
Join [Portfolio projects]..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
