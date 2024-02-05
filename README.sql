-- Goal: clean data and make it usable

USE Cleaning_data_project;

SELECT * FROM nashville_housing_data_for_data_cleaning;

-- Standardize/change data format
ALTER TABLE nashville_housing_data_for_data_cleaning
MODIFY SaleDate Date;

-- Populate Property Address data

SELECT *
FROM nashville_housing_data_for_data_cleaning
ORDER BY ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM nashville_housing_data_for_data_cleaning a -- joining two same tables together
JOIN nashville_housing_data_for_data_cleaning b
	ON a.ParcelID = b.ParcelID -- where ID is the same
    AND a.UniqueID <> b.UniqueID -- but it is not the same row – they have distinct UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE nashville_housing_data_for_data_cleaning a -- updating the database 
JOIN nashville_housing_data_for_data_cleaning b
ON a.ParcelID = b.ParcelID 
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress) -- adding data to empty cells
WHERE a.PropertyAddress IS NULL;

-- Breaking out Adddress into Individual Columns (address, city, state)

SELECT PropertyAddress
FROM nashville_housing_data_for_data_cleaning;

SELECT
SUBSTRING_INDEX(PropertyAddress, ',', 1) AS PropertyAddressAddress
, SUBSTRING_INDEX(PropertyAddress, ',', -1) AS PropertyAddressCity
, SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1) AS OwnerAddressCity
, SUBSTRING_INDEX(OwnerAddress, ',', 1) AS OwnerAddressAddress
, SUBSTRING_INDEX(OwnerAddress, ',', -1) AS OwnerAddressState
FROM nashville_housing_data_for_data_cleaning;

ALTER TABLE nashville_housing_data_for_data_cleaning -- creates table PROPERTY ADDRESS
ADD PropertySplitAddress NVARCHAR(255);

UPDATE nashville_housing_data_for_data_cleaning -- adds data to that table
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1);

ALTER TABLE nashville_housing_data_for_data_cleaning -- creates table PROEPRTY CITY
ADD PropertySplitCity NVARCHAR(255);

UPDATE nashville_housing_data_for_data_cleaning
SET PropertySplitCity = SUBSTRING_INDEX(PropertyAddress, ',', -1);

ALTER TABLE nashville_housing_data_for_data_cleaning -- creates table OWNER ADDRESS
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE nashville_housing_data_for_data_cleaning
SET OwnerSplitAddress = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1);

ALTER TABLE nashville_housing_data_for_data_cleaning -- creates table OWNER CITY
ADD OwnerSplitCity NVARCHAR(255);

UPDATE nashville_housing_data_for_data_cleaning
SET OwnerSplitCity = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE nashville_housing_data_for_data_cleaning -- creates table OWNER STATE
ADD OwnerSplitState NVARCHAR(255);

UPDATE nashville_housing_data_for_data_cleaning
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);


-- Change Y and N to Yes and No in 'Sold as Vacant' field

SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM nashville_housing_data_for_data_cleaning
GROUP BY SoldAsVacant
ORDER BY 2;

UPDATE nashville_housing_data_for_data_cleaning
SET SoldAsVacant = CASE
                    WHEN UPPER(TRIM(SoldAsVacant)) = 'Y' THEN 'Yes'
                    WHEN UPPER(TRIM(SoldAsVacant)) = 'N' THEN 'No'
                    ELSE SoldAsVacant
                   END;

-- Remove duplicates

SELECT UniqueID
FROM nashville_housing_data_for_data_cleaning
WHERE (ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference) IN (
    SELECT ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
    FROM nashville_housing_data_for_data_cleaning
    GROUP BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
    HAVING COUNT(*) > 1
);

DELETE FROM nashville_housing_data_for_data_cleaning
WHERE UniqueID IN (
    SELECT UniqueID
    FROM nashville_housing_data_for_data_cleaning
    WHERE (ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference) IN (
        SELECT ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
        FROM nashville_housing_data_for_data_cleaning
        GROUP BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
        HAVING COUNT(*) > 1
    )
);

-- Delete unused columns

ALTER TABLE nashville_housing_data_for_data_cleaning
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;

-- Rename Columns

ALTER TABLE nashville_housing_data_for_data_cleaning
CHANGE PropertySplitAddress PropertyAddress VARCHAR(250), 
CHANGE PropertySplitCity PropertyCity VARCHAR(250),
CHANGE OwnerSplitAddress OwnerAddress VARCHAR(250), 
CHANGE OwnerSplitCity OwnerCity VARCHAR(250),
CHANGE OwnerSplitState OwnerState VARCHAR(250);

SELECT *
FROM nashville_housing_data_for_data_cleaning;



