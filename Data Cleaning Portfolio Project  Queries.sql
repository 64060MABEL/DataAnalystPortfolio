
/*

 Cleaning Data in sql queries

 */
 -- Step 1 - Understand the dataset
 Select * From [Portfolio projects].[dbo].[NashvilleHousing]
 -----------------------------------------------------------------------
-- Step 2 
-- Standardize Date Format

 Select SaleDateConverted,CONVERT ( Date,SaleDate)
 From [Portfolio projects].[dbo].[NashvilleHousing]

 Alter Table NashvilleHousing
 Add SaleDateConverted Date;

 Update NashvilleHousing
 Set SaleDateConverted = Convert(Date,SaleDate) -- can remove sale date later
-----------------------------------------------------------------------------
-- Step 3  
-- populate property address data using self join
	 
Select PropertyAddress
From [Portfolio projects].[dbo].[NashvilleHousing]

-- Performing a self join using col unique id and parcel id
	 
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.propertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From [Portfolio projects].[dbo].[NashvilleHousing] a
JOIN [Portfolio projects].[dbo].[NashvilleHousing] b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is Null

Update a 
Set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From [Portfolio projects].[dbo].[NashvilleHousing] a
JOIN [Portfolio projects].[dbo].[NashvilleHousing] b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is Null

----------------------------------------------------------------------------
-- Step 4 
-- Breaking out Address into Individual columns(Address, City, State)(Split Address)
	 
Select substring (propertyAddress,1,CHARINDEX(',',PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress,CHARINDEX(',',propertyAddress)+ 1,LEN(PropertyAddress)) as Address
From [Portfolio projects].[dbo].[NashvilleHousing] 

Alter Table [Portfolio projects].[dbo].[NashvilleHousing] 
Add PropertySplitAdress Nvarchar(255)

Update [Portfolio projects].[dbo].[NashvilleHousing] 
Set PropertySplitAdress = SUBSTRING(PropertyAddress, 1, Charindex(',',PropertyAddress)-1)

Alter Table [Portfolio projects].[dbo].[NashvilleHousing] 
Add PropertySplitCity Nvarchar(255);

Update [Portfolio projects].[dbo].[NashvilleHousing] 
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',propertyAddress)+ 1,LEN(PropertyAddress))

Select *  From [Portfolio projects].[dbo].[NashvilleHousing] 

Select
PARSENAME(REPLACE(OwnerAddress,',','.'),3)
,PARSENAME(REPLACE(OwnerAddress,',','.') , 2)
,PARSENAME(REPLACE(OwnerAddress,',','.'), 3)
From [Portfolio projects].[dbo].[NashvilleHousing] 

Alter Table [Portfolio projects].[dbo].[NashvilleHousing] -- 1
Add OwnerSplitAd Nvarchar(255);

Update [Portfolio projects].[dbo].[NashvilleHousing] 
Set OwnerSplitAd = PARSENAME(Replace (OwnerAddress,',','.'),3)

Alter Table [Portfolio projects].[dbo].[NashvilleHousing]
Add OwnerSplitCity Nvarchar(255);

Update [Portfolio projects].[dbo].[NashvilleHousing]
SET OwnerSplitCity = PARSENAME(Replace (OwnerAddress,',','.'),2)

Alter Table [Portfolio projects].[dbo].[NashvilleHousing]
Add OwnerSplitState Nvarchar(255);

Update [Portfolio projects].[dbo].[NashvilleHousing]
SET OwnerSplitState = PARSENAME(Replace (OwnerAddress,',','.'),1) -- This is very important and is used Frequently.

Select * from [Portfolio projects].[dbo].[NashvilleHousing];

--------------------------------------------------------------------------------------------------------------------
-- Step 5 
-- Standardize the values using case
-- Change Y and N to Yes and No in "sold as Vacant" field

Select Distinct (Soldasvacant), Count(Soldasvacant)
From [Portfolio projects].[dbo].[NashvilleHousing]
Group by SoldAsVacant
order by 2

Select SoldasVacant
, Case when SoldasVacant = 'Y' Then 'Yes'
  When SoldasVacant = 'N' Then 'No'
  Else SoldasVacant
  End
 From [Portfolio projects].[dbo].[NashvilleHousing]

Update [Portfolio projects].[dbo].[NashvilleHousing]
Set SoldasVacant =  Case when SoldasVacant = 'Y' Then 'Yes'
When SoldasVacant = 'N' Then 'No'
Else SoldasVacant
end

---------------------------------------------------------------------------------------------------
-- Step 6
-- Remove Duplicates
-- Can use other options like rank, row number.
	
With RowNumCTE as (Select *,
ROW_NUMBER() over (
Partition by parcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			Order by
			UniqueId
			)row_num
From [Portfolio projects].[dbo].[NashvilleHousing]
--Orderby parcelid
)
Select *  From RowNumCTE
Where row_num > 1
Order by PropertyAddress -- Used delete to remove dup records

----------------------------------------------------------------------------------------------------------------------
-- Step 7 
-- Deleted Unused Columns
	
Select * from [Portfolio projects].[dbo].[NashvilleHousing]
Alter Table [Portfolio projects].[dbo].[NashvilleHousing]
Drop Column OwnerAddress,TaxDistrict,PropertyAddress

Alter Table [Portfolio projects].[dbo].[NashvilleHousing]
Drop Column SaleDate
