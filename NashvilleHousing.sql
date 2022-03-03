/*

Cleaning Data

*/

SELECT * 
FROM 
NashvilleHousing.dbo.HousingTable

/* Standardize Date Format */

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM NashvilleHousing.dbo.HousingTable

-- Add new sale date column with correct formatting
ALTER TABLE NashvilleHousing.dbo.HousingTable
ADD SaleDateConverted Date;

Update NashvilleHousing.dbo.HousingTable 
SET SaleDateConverted = CONVERT(Date, SaleDate)

/* Populate Property Address Data*/

-- Find all NULL values for property address
SELECT T1.ParcelID, T1.PropertyAddress, T2.ParcelID, T2.PropertyAddress, ISNULL(T1.PropertyAddress, T2.PropertyAddress)
FROM NashvilleHousing.dbo.HousingTable T1
JOIN NashvilleHousing.dbo.HousingTable T2
	ON T1.ParcelID = T2.ParcelID -- Same Parcel ID
	AND T1.[UniqueID ] <> T2.[UniqueID ] -- Different Unique ID
WHERE T1.PropertyAddress IS NULL

-- Update NULL property addresses with property address with same parcel IDs and different unique IDs
UPDATE T1
SET PropertyAddress = ISNULL(T1.PropertyAddress, T2.PropertyAddress)
FROM NashvilleHousing.dbo.HousingTable T1
JOIN NashvilleHousing.dbo.HousingTable T2
	ON T1.ParcelID = T2.ParcelID -- Same Parcel ID
	AND T1.[UniqueID ] <> T2.[UniqueID ] -- Different Unique ID
WHERE T1.PropertyAddress IS NULL

/* Breaking up address columns into individual columns (Address, City, State) */

-- Looking at property address
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address, -- Return address portion of property address
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City -- Return city portion of property address
FROM NashvilleHousing.dbo.HousingTable


-- Add two new columns with the address and city 
ALTER TABLE NashvilleHousing.dbo.HousingTable
ADD PropertySplitAddress NVARCHAR(255);

Update NashvilleHousing.dbo.HousingTable 
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing.dbo.HousingTable
ADD PropertySplitCity NVARCHAR(255);

Update NashvilleHousing.dbo.HousingTable 
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- Looking at owner address (Using PARSENAME instead of SUBSTRING)

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing.dbo.HousingTable

-- Add new columns for owner address, city, state
ALTER TABLE NashvilleHousing.dbo.HousingTable
ADD OwnerSplitAddress NVARCHAR(255);

Update NashvilleHousing.dbo.HousingTable 
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing.dbo.HousingTable
ADD OwnerSplitCity NVARCHAR(255);

Update NashvilleHousing.dbo.HousingTable 
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing.dbo.HousingTable
ADD OwnerSplitState NVARCHAR(255);

Update NashvilleHousing.dbo.HousingTable 
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

/* Change Y and N to Yes and No in "Sold as Vacant" field */

-- Check all the distinct values for SoldAsVacant
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing.dbo.HousingTable
GROUP BY SoldAsVacant
ORDER BY 2

-- Test updating the Y an N to Yes and No
SELECT SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM NashvilleHousing.dbo.HousingTable

-- Update in Housing table
UPDATE NashvilleHousing.dbo.HousingTable
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

/* Remove Duplicates */

-- Create a new column that partitions over the selected columns and will mark it as 2 if the same
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
			     PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID) row_num

FROM NashvilleHousing.dbo.HousingTable
)
SELECT * 
FROM RowNumCTE
WHERE row_num > 1

--Delete duplicate columns
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
			     PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID) row_num

FROM NashvilleHousing.dbo.HousingTable
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

/* Delete unused columns */

ALTER TABLE NashvilleHousing.dbo.HousingTable
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate