---------------------------------------------------------
------------------PARALLEL PROGRAMMING-------------------
-------------------COURSE WORK PART 2--------------------
----       --ADA. SEMAPHORES. PROTECTED UNITS--     -----
----              MA = MB*MC + MO*ME*a              -----
---------------------------------------------------------
-------------     MAIN MODULE PRG2     ------------------
---------------------------------------------------------
-----------------CREATED ON 20.03.2016-------------------
----------------BY OLEG PEDORENKO, IP-31-----------------
---------------------------------------------------------

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;
with Ada.Real_Time;      use Ada.Real_Time;
with Ada.Command_Line; use Ada.Command_Line;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Data;

procedure p03 is

  N: Integer := 8;
  P: Integer := 2;
  H: Integer := 4;
-- t_start - start time; t_copy - copy start time; t_calc - calc start time; t_finish - finish time
  t_start, t_copy, t_calc, t_finish: Ada.Real_Time.Time;  
  
  procedure Write_Time_To_File(
    Start_Time, End_Time: Ada.Real_Time.Time;
    File_Name: String; Comment: String := "") is
    Work_Time: Duration;
    My_File: Ada.Text_IO.File_type;
  begin
    Work_Time := Ada.Real_Time.To_Duration(End_Time - Start_Time);
    Put("N =   "); Put(N);
    Put(Duration'Image(Work_Time)); Put("s. "); Put_Line("(" & Comment & ")");
    
    Create (File => My_File, Mode => Out_File, 
      Name => File_Name);
    Put(File => My_File, 
      Item => Trim(Duration'Image(Work_Time), 
                Ada.Strings.Left));
    Put(File => My_File, Item => ";");
    Close(My_File);  
  end;
  
begin
  --Read N and P from command line
  if(Argument_Count > 0) then 
    N := Integer'Value(Argument(1));
  end if;  
  if(Argument_Count > 1) then 
    P := Integer'Value(Argument(2));
  end if;  
  H := Integer(Float'Ceiling(Float(N)/Float(P)));
  
  declare  
    -- Types
    package Data_S is new Data(N, 100); use Data_S;
    subtype Range_H is Integer range 1..H;
    subtype Range_P is Integer range 1..P;
    subtype Range_2P is Integer range 2..P;
        
    -- Task type for T1 (Task that enters data)
    task type T1 is
      pragma Storage_Size(100000000);
    end T1;
    
    task type TX(I: Integer) is
      pragma Storage_Size(100000000);
      entry Task_Range(First, Last: in Integer);
      entry Data(d_MB, d_MCh, d_MO, d_MEh: in Proto_Matrix; d_a: in Scalar);
      entry Result(r_MAh: out Proto_Matrix);
    end TX;

    T1_T: access T1;
    TX_Arr: array(Range_2P) of access TX;
    
    task body T1 is
      B, E: Integer;
      MA, MB, MC, MO, ME: Matrix;
      a: Scalar;
      Sum1, Sum2: Scalar;
    begin
      Put_Line("Task T1 started");
      --Initialize MA
      Fill(MA);
      --Enter MB, MC, MO, ME, a
      Put_Line("MB =   "); Input(MB); 
      Put_Line("MC =   "); Input(MC); 
      Put_Line("MO =   "); Input(MO); 
      Put_Line("ME =   "); Input(ME);      
      Put_Line("a =    "); Input(a); Put(a); Put_Line("");
      t_copy := Clock;
      -- Надсилання даних по задачах;
      for I in Range_2P loop
        B := (H*(I-1) + 1);
        E := (H*I);
        if (I = P) then
          E := N;
        end if;    
        TX_Arr(I).Task_Range(B, E);
        TX_Arr(I).Data(MB, MC(B..E), MO, ME(B..E), a);
      end loop;
      t_calc := Clock;
      -- Обчислення даних;
      ---------
      begin
        for I in 1..N loop
          for J in Range_H loop
            Sum1 := 0.0;
            Sum2 := 0.0;
            for K in 1..N loop
              Sum1 := Sum1 + (MB(I)(K) * MC(K)(J)); --MB * MCh
              Sum2 := Sum2 + (MO(I)(K) * ME(K)(J)); -- MO * MEh
          end loop;
            MA(J)(I) := Sum1 + Sum2 * a; -- Sum1 + Sum2 * aa;
          end loop;
        end loop;
      end;      
      ---------
      -- Прийом даних;
      for I in Range_2P loop
        B := (H*(I-1) + 1);
        E := (H*I);
        if (I = P) then
          E := N;
        end if;       
        TX_Arr(I).Result(MA(B..E));
      end loop;      
      -- Виведення результату;
      Put_Line("MA =   "); Output(MA);
      t_finish := Clock;
      Write_Time_To_File(t_start, t_finish, 
        Trim(Integer'Image(N), Ada.Strings.Left) & "-all",
        "Total work time");
      Write_Time_To_File(t_copy, t_finish, 
        Trim(Integer'Image(N), Ada.Strings.Left) & "-copy_calc",
        "Copy and calculation time");
      Write_Time_To_File(t_calc, t_finish, 
        Trim(Integer'Image(N), Ada.Strings.Left) & "-calc",
        "Calculation time");
      Put_Line("Task T1 finished");
    end T1;
    
    task body TX is
      B, E: Integer := 0;
    begin
      Put_Line("Task T" & Integer'Image(I) &" started");
      accept Task_Range(First, Last: in Integer) do
        B := First;
        E := Last;
      end Task_Range;
      declare 
        -- Types
        subtype Range_T is Integer range B..E;
        -- Vars
        l_MB,  l_MO: Matrix;
        l_MCh, l_MEh: Proto_Matrix(Range_T);
        l_MAh: Proto_Matrix(Range_T);
        l_a: Scalar;
        Sum1, Sum2: Scalar;
      begin
        -- Прийом даних з Т1
        accept Data(d_MB, d_MCh, d_MO, d_MEh: in Proto_Matrix; d_a: in Scalar) do
          l_MB := d_MB;
          l_MCh := d_MCh;
          l_MO := d_MO;
          l_MEh := d_MEh;
          l_a := d_a;
        end Data;
        -- Обчислення МАн
        ------
        begin
          for I in 1..N loop
            for J in Range_T loop
              Sum1 := 0.0;
              Sum2 := 0.0;
              for K in 1..N loop
                Sum1 := Sum1 + (l_MB(I)(K) * l_MCh(J)(K)); --MB * MCh
                Sum2 := Sum2 + (l_MO(I)(K) * l_MEh(J)(K)); -- MO * MEh
              end loop;
              l_MAh(J)(I) := Sum1 + Sum2 * l_a; -- Sum1 + Sum2 * aa;
            end loop;
          end loop;  
          Output(l_MCh);      
        end;
        ------
        -- Передати МАн у Т1
        accept Result(r_MAh: out Proto_Matrix) do
          r_MAh := l_MAh;
        end Result;
      end; 
      Put_Line("Task T" & Integer'Image(I) &" finished");    
    end TX;
  
  begin    
    t_start := Clock;
    T1_T := new T1;
    for I in Range_2P loop
      TX_Arr(I) := new TX(I);
    end loop;
  end;
  
end p03;