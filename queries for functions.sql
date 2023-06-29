
-- FUNCTION: public.required_recommended_courses(character)

-- DROP FUNCTION IF EXISTS public.required_recommended_courses(character);

CREATE OR REPLACE FUNCTION public.required_recommended_courses(
	course character)
    RETURNS TABLE(course_code character, course_title character) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    IF (
        (SELECT typical_season FROM "Course" co WHERE co.course_code = course) = 'spring'
    ) THEN
	
RETURN QUERY
SELECT cd.main, cr.course_title
        FROM "Course" cr
        JOIN "Course_depends" cd ON (cr.course_code = cd.main)
        WHERE cd.dependent = course
            AND (
                cr.typical_year < (
                    SELECT cr1.typical_year
                    FROM "Course" cr1
                    WHERE cr1.course_code = course
                )
                OR (
                    cr.typical_year = (
                        SELECT cr1.typical_year
                        FROM "Course" cr1
                        WHERE cr1.course_code = course
                    )
                    AND (
                        SELECT cr1.typical_season
                        FROM "Course" cr1 
						 
                        WHERE cr1.course_code = course
                    ) = 'winter'
                )
            )
            AND cd.main <> course;
    ELSE
	
		RETURN QUERY
        SELECT cd.main, cr.course_title
        FROM "Course" cr
        JOIN "Course_depends" cd ON (cr.course_code = cd.dependent)
        WHERE cd.dependent = course
            AND cr.typical_year < (
                SELECT cr1.typical_year
                FROM "Course" cr1
                WHERE cr1.course_code = course
            )
            AND cd.main <> course;
    END IF;
END;
$BODY$;

ALTER FUNCTION public.required_recommended_courses(character)
    OWNER TO postgres;



-- FUNCTION: public.insert_thesis(character varying, character varying, integer)

-- DROP FUNCTION IF EXISTS public.insert_thesis(character varying, character varying, integer);

CREATE OR REPLACE FUNCTION public.insert_thesis(
	tam character varying,
	title character varying,
	pid integer)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    cnum INT;
	i INT;
	tID INT ;
	professor_amka character varying;
	is_supervisor BOOLEAN;
	diploma_grade numeric;
    counter INTEGER ;
	p_grade numeric;
	re_grade numeric;
	obli_grade numeric;
	re_grade_total numeric;
	diff integer;
	courses integer;
	stud_amka character varying;
begin
create table temp(
 	gravity_factor numeric,
    course_code character(7)
);

insert into temp(gravity_factor,course_code)
select units,course_code from "Course" ;

update temp
set gravity_factor=  
  CASE
		WHEN gravity_factor = 1 THEN 1
        WHEN gravity_factor = 2 THEN 1
        WHEN gravity_factor = 3 THEN 1.5
        WHEN gravity_factor = 4 THEN 1.5
        WHEN gravity_factor = 5 THEN 2
    END;
	
stud_amka =(select amka from "Student" where am=tam);
tID := FLOOR(random() * 1000000)::int;
courses=(select count("MinCourses")  from "Program" where "ProgramID"=pid);
IF (((SELECT MAX("DiplomaNum") FROM "Diploma") + 1) IS NULL) then
counter := 1;
ELSE
counter := (SELECT MAX("DiplomaNum") FROM "Diploma") + 1;
END IF;
IF ((SELECT "Obligatory" FROM "Program" WHERE "ProgramID" = pid) = 'true' )
then
if ((select count(co.course_code) 
from "Program" pro join "ProgramOffersCourse" poc using("ProgramID") JOIN "Joins" jo using("ProgramID") JOIN "Course" co  on(poc."CourseCode"=co.course_code) join "Register" re on (jo."StudentAMKA"=re.amka) join "Student" st using (amka)
where "ProgramID"=pid AND re.register_status='pass' and st.am=tam) >= courses)
then 

insert into "Thesis"("ThesisID","Grade","Title","StudentAMKA","ProgramID")
values(tID,FLOOR(RANDOM() * (10 - 5 + 1) + 5),title,stud_amka,pid);

SELECT "CommitteeNum" INTO cnum
FROM "Program" 
WHERE "ProgramID" = pid;

for i in 1..cnum loop
	
	SELECT  prof.amka INTO professor_amka
	from "Program" pr  join "ProgramOffersCourse" poc using ("ProgramID") join "Course" cr on( poc."CourseCode"=cr.course_code) join "Teaches" te using(course_code) join "Professor" prof using (amka)
	where pr."ProgramID"=pid and  NOT EXISTS (SELECT 1
    FROM "Committee"
    WHERE "ProfessorAMKA" = prof.amka
      AND "ThesisID" = tID )
	
	order by random()
    limit 1;
	
	is_supervisor := (RANDOM() > 0.5);
	
	insert into "Committee"("ProfessorAMKA","ThesisID","Supervisor")
	VALUES (professor_amka,tID, is_supervisor);
	
end loop;

ELSE RAISE NOTICE'THIS THESIS CAN NOT BE CREATED';
END IF;
ELSE RAISE NOTICE 'THIS PROGRAM DOES NOT HAVE A DIPLOMA TYPE AS OBLIGATORY';
END IF;

	

if((select count(co.course_code)
			from "Student" st join "Register" re using(amka) join "Course" co using(course_code) join "ProgramOffersCourse" poc on(co.course_code=poc."CourseCode") join "Program" using("ProgramID") join "Joins" using("ProgramID")
			where "ProgramID"=pid and st.am=tam and re.register_status='pass' ) >= courses) then
			 
   IF NOT EXISTS ( SELECT *
                FROM "SeasonalProgram"
                   WHERE "ProgramID" = pid) THEN
	    if ((SELECT "Obligatory" FROM "Program" WHERE "ProgramID" = pid) = 'false' ) then
	
		
					  
		             diploma_grade=(select avg(re.final_grade)
					  from "Student" st join "Register" re using(amka) join "Course" co using(course_code) join temp tmp using (course_code) join "ProgramOffersCourse" poc on(co.course_code=poc."CourseCode") join "Program" pr using("ProgramID") join "Joins" using("ProgramID")
					  where pr."ProgramID"=pid and st.am=tam and co.obligatory='true' and re.register_status='pass'
					  order by random()
					  limit courses);
			         
					 insert into "Diploma"("DiplomaNum","DiplomaGrade","DiplomaTitle","StudentAMKA","ProgramID")
					 values(counter,diploma_grade,title,stud_amka,pid);
					  
			else		  
		 			
					if((select count(co.course_code)
			from "Student" st join "Register" re using(amka) join "Course" co using(course_code) join "ProgramOffersCourse" poc on(co.course_code=poc."CourseCode") join "Program" using("ProgramID") join "Joins" using("ProgramID")
			where "ProgramID"=pid and st.am=tam and co.obligatory='true' and re.register_status='pass' ) >=courses) then
					 
		             obli_grade= (select (sum(re.final_grade * tmp.gravity_factor)) / sum(tmp.gravity_factor)
					  from "Student" st join "Register" re using(amka) join "Course" co using(course_code) join temp tmp using (course_code) join "ProgramOffersCourse" poc on(co.course_code=poc."CourseCode") join "Program" pr using("ProgramID") join "Joins" using("ProgramID")
					  where pr."ProgramID"=pid and st.am=tam and co.obligatory='true' and re.register_status='pass'
					  order by random()
					  limit courses);
				  
					  p_grade=obli_grade;
					  diploma_grade=p_grade*0.8+(select th."Grade" from "Thesis" th join "Student" st on(th."StudentAMKA"=st.amka) where st.am=tam)*0.2;
					  
					  insert into "Diploma"("DiplomaNum","DiplomaGrade","DiplomaTitle","StudentAMKA","ProgramID")
					 values(counter,diploma_grade,title,stud_amka,pid);
		 			else
					
					obli_grade =(select sum(re.final_grade * tmp.gravity_factor)  /sum(tmp.gravity_factor)
					from "Student" st join "Register" re using(amka) join "Course" co using(course_code) join temp tmp using (course_code) join "ProgramOffersCourse" poc on(co.course_code=poc."CourseCode") join "Program" pr using("ProgramID") join "Joins" using("ProgramID")
					  where pr."ProgramID"=pid and st.am=tam and co.obligatory='true' and re.register_status='pass' );
					  
					  diff =(select "MinCourses" from "Program" where "ProgramID"=pid)-(select count(co.course_code)
						from "Student" st join "Register" re using(amka) join "Course" co using(course_code) join "ProgramOffersCourse" poc on(co.course_code=poc."CourseCode") join "Program" using("ProgramID") join "Joins" using("ProgramID")
						where "ProgramID"=pid and st.am=tam and co.obligatory='true' and re.register_status='pass' );
			  
					  for i in 1..diff loop
						re_grade =(select sum(re.final_grade * tmp.gravity_factor) / sum(tmp.gravity_factor)
							  from "Student" st join "Register" re using(amka) join "Course" co using(course_code) join temp tmp using (course_code) join "ProgramOffersCourse" poc on(co.course_code=poc."CourseCode") join "Program" pr using("ProgramID") join "Joins" using("ProgramID")
							  where pr."ProgramID"=pid and st.am=tam and co.obligatory='false'and re.register_status='pass' and co.course_code  in (select co.course_code from "Register" re join "Course" co using(course_code) where co.obligatory='false'order by final_grade) );
							 re_grade_total= re_grade_total+re_grade; 
						end loop;
				
						p_grade=obli_grade+re_grade_total;
						diploma_grade=p_grade*0.8+(select th."Grade" from "Thesis" th join "Joins" jo using("ProgramID") join "Student" st on (jo."StudentAMKA"=st.amka) where st.am=tam)*0.2;
						insert into "Diploma"("DiplomaNum","DiplomaGrade","DiplomaTitle","StudentAMKA","ProgramID")
							 values(counter,diploma_grade,title,stud_amka,pid);
					end if;

	    end if;
  else 
	if ((SELECT "Obligatory" FROM "Program" WHERE "ProgramID" = pid) = 'false' ) then
		
					  
		             diploma_grade=(select avg(re.final_grade)
					  from "Student" st join "Register" re using(amka) join "Course" co using(course_code) join temp tmp using (course_code) join "ProgramOffersCourse" poc on(co.course_code=poc."CourseCode") join "Program" pr using("ProgramID") join "Joins" using("ProgramID")
					  where pr."ProgramID"=pid and st.am=tam and co.obligatory='true' and re.register_status='pass'
					  order by random()
					  limit courses);
					 insert into "Diploma"("DiplomaNum","DiplomaGrade","DiplomaTitle","StudentAMKA","ProgramID")
					 values(counter,diploma_grade,title,stud_amka,pid);
					 
		
	else 
		
					  
					   p_grade=(select avg(re.final_grade)
					  from "Student" st join "Register" re using(amka) join "Course" co using(course_code) join temp tmp using (course_code) join "ProgramOffersCourse" poc on(co.course_code=poc."CourseCode") join "Program" pr using("ProgramID") join "Joins" using("ProgramID")
					  where pr."ProgramID"=pid and st.am=tam and co.obligatory='true' and re.register_status='pass'
					  order by random()
					  limit courses);
			         diploma_grade=p_grade*0.8+(select th."Grade" from "Thesis" th join "Student" st on(th."StudentAMKA"=st.amka) where st.am=tam)*0.2;
					 
					 insert into "Diploma"("DiplomaNum","DiplomaGrade","DiplomaTitle","StudentAMKA","ProgramID")
					 values(counter,diploma_grade,title,stud_amka,pid);
		
		end if;
	end if;
end if;
 DROP TABLE temp;
end;
$BODY$;

ALTER FUNCTION public.insert_thesis(character varying, character varying, integer)
    OWNER TO postgres;



-- FUNCTION: public.check_registration_validity()

-- DROP FUNCTION IF EXISTS public.check_registration_validity();

CREATE OR REPLACE FUNCTION public.check_registration_validity()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE total_units integer;
BEGIN
IF OLD.register_status <> 'proposed' and  OLD.register_status <> 'requested' or NEW.register_status <> 'approved' then
return new;
end if;

SELECT COALESCE(sum(units),0)
into total_units
from "Course"
join "Register" using (course_code)
join "Student" using (amka)
where "Student".amka=NEW.amka and register_status='pass';

IF  EXISTS (
	SELECT 1
	from "Course"
	join "Register" using (course_code)
	join "Student" using (amka)
	where "Student".amka = NEW.amka
	and (total_units + (select units from "Course" where course_code = new.course_code) >50) 
	OR ((select 1 from required_recommended_courses(course_code) rc join "Course" co using(course_code) join "Course_depends" cd on (co.course_code= cd.dependent) join "Register" using(course_code) where mode='required' and register_status <> 'pass' ) is null)
) then
NEW.register_status = 'rejected';
end if;
return new;
END;
$BODY$;

ALTER FUNCTION public.check_registration_validity()
    OWNER TO postgres;



-- Trigger: check_registration_validity

-- DROP TRIGGER IF EXISTS check_registration_validity ON public."Register";

CREATE TRIGGER check_registration_validity
    BEFORE UPDATE OF register_status
    ON public."Register"
    FOR EACH ROW
    EXECUTE FUNCTION public.check_registration_validity();



