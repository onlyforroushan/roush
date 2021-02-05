<# 
.SYNOPSIS  
	 Recursively copies file from one fileshare to another fileshare, acrosss storage.
	 
	 
.DESCRIPTION
     This script creates the required directory structure on destination file share
	 Uploads the .csv reports to the same directory structure, from where it was picked.

.PARAMETER
	fileShareName- Name of the parent fileshare, from where data is going to be copied.
	StorageAccountName- Name of the parent storage account, of which parameter fileShareName is part of and also from where data is going to be copied.
	StorageAccessKey- Access key of storage (StorageAccountName)
	context1- context1 is the access token of storage account- StorageAccountName
	DestStorageAccountName- Name of the destination storage account where the data is going to get copied
	DestStorageAccessKey- Access key of storage (DestStorageAccountName)
	destcontext1- destcontext1 is the access token of storage account- (DestStorageAccountName)
	SrcShare- this is same as parameter fileShareName 
	DestShare- Name of the destination fileshare, where data will be copied. 
	
#>


#Update the below variables in order to proceed further
$fileShareName="asuse21digip1pfs"
$StorageAccountName = "asuse21digip1pfssa"
$StorageAccessKey = "Cac/c42ggt0GngWZ0h1JOFO7wx+xvjDTYxfZVI4cqTYC14aoXDiB4BfNw8peywOwT+l7ih/KuLxxebPSqUDWhg=="
$context1=New-AzureStorageContext $StorageAccountName $StorageAccessKey
$DestStorageAccountName = "funcmi73qgdmjeosq"
$DestStorageAccessKey = "xZjU0r5g5fU+/ieAbwc22OmVtFY5BJdQuF8OZsFd7hGHYLzQFGg9ZCpsVnQi5u6Wi/nigb8jdupUGo0YaXBphg=="
$destcontext1=New-AzureStorageContext $DestStorageAccountName $DestStorageAccessKey
$SrcShare = "asuse21digip1pfs"
$DestShare = "amuse11logsa01toamuse11logehns02func"
$aaaa = (New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey "Cac/c42ggt0GngWZ0h1JOFO7wx+xvjDTYxfZVI4cqTYC14aoXDiB4BfNw8peywOwT+l7ih/KuLxxebPSqUDWhg==")

#Function to create destination directories
#Function to copy to destination

Function GetFiles  
{   
	
	#This below variable is going to be the first directory inside fileshae
#File-Depth_level-0
    $directories = (Get-AzureStorageFile -Context $aaaa -ShareName $fileShareName) 

    foreach($directory in $directories)
    {
         if ($directory.Name -like "*.csv*") 
		 {
             Write-Output $directory 
			 Start-AzureStorageFileCopy -SrcFilePath $directory.Name -SrcShareName $SrcShare -DestShareName $DestShare -DestFilePath $directory.Name -Context $context1 -DestContext $destcontext1 -Force
			 
		 }

#File-Depth_level-1
         else {
			 write-host $directory
			 Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $directory
             $files = Get-AzureStorageFile -Context $aaaa -ShareName $fileShareName -Path $directory.Name | Get-AzureStorageFile -ErrorAction SilentlyContinue
                foreach ($file in $files)
				{
					if ($file.Name -like "*.csv*")
					{
						Write-Output $file
						$dirx = $directory.Name
						$dirxf = $file.Name
						$xy = $dirx + "/" + $dirxf
						Start-AzureStorageFileCopy -SrcFilePath $xy -SrcShareName $SrcShare -DestShareName $DestShare -DestFilePath $xy -Context $context1 -DestContext $destcontext1 -Force
						
					}

#File-Depth_level-2
	
					else {
					     write-host $file.Name
						 $dira = $dirx + "/" + $file.Name
						 Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $dira
						 $bbbb = (New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey "Cac/c42ggt0GngWZ0h1JOFO7wx+xvjDTYxfZVI4cqTYC14aoXDiB4BfNw8peywOwT+l7ih/KuLxxebPSqUDWhg==")
						 
						 $a = $directory.Name
						 $b = $file.Name
						 $abconcat = $a + "/" + $b
						 Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $a
						 Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $abconcat
						 $files_depth1 = (Get-AzureStorageFile -Context $bbbb -ShareName $fileShareName -Path $abconcat | Get-AzureStorageFile -ErrorAction SilentlyContinue)
						 foreach ($file1 in $files_depth1)
						 {
							if ($file1.Name -like "*.csv*")
							{
							Write-Output $file1
							$ab = $a + "/" + $b
							$abf = $a + "/" + $b + "/" + $file1.Name
							#$diraf = $dira + "/" + $file1.Name
							#Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $a
							#Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $ab
							#Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $abf
							Start-AzureStorageFileCopy -SrcFilePath $abf -SrcShareName $SrcShare -DestShareName $DestShare -DestFilePath $abf -Context $context1 -DestContext $destcontext1 -Force

							}

#File-Depth_level-3
						    else
								{
										$cccc = (New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey "Cac/c42ggt0GngWZ0h1JOFO7wx+xvjDTYxfZVI4cqTYC14aoXDiB4BfNw8peywOwT+l7ih/KuLxxebPSqUDWhg==")
										
										$c = $directory.Name
										$d = $file.Name
										$e = $file1.Name
										$cde = $c + "/" + $d + "/" + $e 
										$diraf2 = $ab + "/" + $e
										Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $diraf2
										$files_depth2 = (Get-AzureStorageFile -Context $cccc -ShareName $fileShareName -Path $cde | Get-AzureStorageFile -ErrorAction SilentlyContinue)
										foreach ($file2 in $files_depth2)
												{
													if ($file2.Name -like "*.csv*")
														{
													Write-Output $file2
													$cdef = $c + "/" + $d + "/" + $e + "/" + $file2.Name
													Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $cde
#													Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $cdef
#													Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $c + "/" + $d
#													Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $c + "/" + $d + "/" + $e
													Start-AzureStorageFileCopy -SrcFilePath $cdef -SrcShareName $SrcShare -DestShareName $DestShare -DestFilePath $cdef -Context $context1 -DestContext $destcontext1 -Force
										
									}

#File-Depth_level-4									
									else
										{
												$dddd = (New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey "Cac/c42ggt0GngWZ0h1JOFO7wx+xvjDTYxfZVI4cqTYC14aoXDiB4BfNw8peywOwT+l7ih/KuLxxebPSqUDWhg==")
												
												$f = $directory.Name
												$g = $file.Name
												$h = $file1.Name
												$i = $file2.Name
												$fghi = $f + "/" + $g + "/" + $h + "/" + $i
												$diraf3 = $cde + "/" + $i
												Write-Output "diraf3 is: " $diraf3
												Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $diraf3
												$files_depth3 = (Get-AzureStorageFile -Context $dddd -ShareName $fileShareName -Path $diraf3 | Get-AzureStorageFile -ErrorAction SilentlyContinue)
												foreach ($file3 in $files_depth3)
												{
													if ($file3.Name -like "*.csv*")
													{
														Write-Output $file3
														$no = $file3.Name
														$fghif = $diraf3 + "/" + $file3.Name
														Write-Output "fghif is: " $fghif
														Start-AzureStorageFileCopy -SrcFilePath $fghif -SrcShareName $SrcShare -DestShareName $DestShare -DestFilePath $fghif -Context $context1 -DestContext $destcontext1 -Force
														
												}
#File-Depth_level-5													
													else
														{
															$eeee = (New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey "Cac/c42ggt0GngWZ0h1JOFO7wx+xvjDTYxfZVI4cqTYC14aoXDiB4BfNw8peywOwT+l7ih/KuLxxebPSqUDWhg==")
															
															$j = $directory.Name
															$k = $file.Name
															$l = $file1.Name
															$m = $file2.Name
															$n = $file3.Name
															$diraf4 = $diraf3 + "/" + $n
															Write-Output "diraf4 is: " $diraf4
															Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $diraf4
															$jklmn = $j + "/" + $k + "/" + $l + "/" + $m + "/" + $n
															
															$files_depth4 = (Get-AzureStorageFile -Context $eeee -ShareName $fileShareName -Path $diraf4 | Get-AzureStorageFile -ErrorAction SilentlyContinue)
															foreach ($file4 in $files_depth4)
															{
																if ($file4.Name -like "*.csv*")
																{
																	Write-Output $file4
																	$jklmnf = $diraf4 + "/" + $file4.Name
																	$nop = $file4.Name
																	
																	Start-AzureStorageFileCopy -SrcFilePath $jklmnf -SrcShareName $SrcShare -DestShareName $DestShare -DestFilePath $jklmnf -Context $context1 -DestContext $destcontext1 -Force
																	
																}

#File-Depth_level-6
														
														else
															{
																$ffff = (New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey "Cac/c42ggt0GngWZ0h1JOFO7wx+xvjDTYxfZVI4cqTYC14aoXDiB4BfNw8peywOwT+l7ih/KuLxxebPSqUDWhg==")
																
																$o = $directory.Name
																$p = $file.Name
																$q = $file1.Name
																$r = $file2.Name
																$s = $file3.Name
																$t = $file4.Name
																$diraf5 = $diraf4 + "/" + $t
																Write-Output "diraf5 is: " $diraf5
																Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $diraf5
																$opqrst = $o + "/" + $p + "/" + $q + "/" + $r + "/" + $s + "/" + $t
																$files_depth5 = (Get-AzureStorageFile -Context $ffff -ShareName $fileShareName -Path $diraf5 | Get-AzureStorageFile -ErrorAction SilentlyContinue)
																foreach ($file5 in $files_depth5)
																	{
																		if ($file5.Name -like "*.csv*")
																		{
																			Write-Output $file5
																			$nope = $file5.Name
																			
																			$opqrstf = $diraf5 + "/" + $nope
																			#Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $o
																			Write-Output "Copying on path" $opqrstf
																			Start-AzureStorageFileCopy -SrcFilePath $opqrstf -SrcShareName $SrcShare -DestShareName $DestShare -DestFilePath $opqrstf -Context $context1 -DestContext $destcontext1 -Force
																			
																		}

#File-Depth_level-7
																
																else
																		{
																			$gggg = (New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey "Cac/c42ggt0GngWZ0h1JOFO7wx+xvjDTYxfZVI4cqTYC14aoXDiB4BfNw8peywOwT+l7ih/KuLxxebPSqUDWhg==")
																			
																			$u = $directory.Name
																			$v = $file.Name
																			$w = $file1.Name
																			$x = $file2.Name
																			$y = $file3.Name
																			$z = $file4.Name
																			$za = $file5.Name
																			$diraf6 = $diraf5 + "/" + $za
																			Get-AzStorageShare -Context $destcontext1 -Name $DestShare | New-AzStorageDirectory -Path $diraf6
																			$uvwxyza = $u + "/" + $v + "/" + $w + "/" + $x + "/" + $y + "/" + $z + "/" + $za
																			$files_depth6 = (Get-AzureStorageFile -Context $gggg -ShareName $fileShareName -Path $diraf6 | Get-AzureStorageFile -ErrorAction SilentlyContinue)
																			foreach ($file6 in $files_depth6)
																				{
																					Write-Output $file6
																					$nopee = $file6.Name
																					$uvwxyzaf = $diraf6 + "/" + $nopee
																					#Copying the maximum depth .csv files to destination file share.
																					Start-AzureStorageFileCopy -SrcFilePath $uvwxyzaf -SrcShareName $SrcShare -DestShareName $DestShare -DestFilePath $uvwxyzaf -Context $context1 -DestContext $destcontext1 -Force
																					
																				}
																		}
																	}
															}
															}
														}
										}
									}
								}
							}
						 }
						 }
				}
         }
    }

}

#Calling function- GetFiles
  
GetFiles
