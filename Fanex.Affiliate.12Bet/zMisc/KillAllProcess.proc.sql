Create  Proc Sp_KillAllProcessInDB 

@DbName VarChar(100)

as
        if db_id(@DbName) = Null 
                begin
                        Print 'DataBase dose not Exist'
                end
        else

                Begin
                        Declare @spId Varchar(30)
                        
                        DECLARE TmpCursor CURSOR FOR
                        Select  'Kill ' + convert(Varchar, spid)  as spId
                        from master..SysProcesses
                        where db_Name(dbID) = @DbName
                        and spId <> @@SpId
                        and dbID <> 0
                        OPEN TmpCursor
                        
                        FETCH NEXT FROM TmpCursor
                        INTO @spId 
                        
                        WHILE @@FETCH_STATUS = 0

                        BEGIN
                                
                                Exec (@spId)
        
                                FETCH NEXT FROM TmpCursor
                                INTO @spId 
                
                        END
                        

                        CLOSE TmpCursor
                        DEALLOCATE TmpCursor

                end             

--To Execute
--Exec Sp_KillAllProcessInDB [DBName]

