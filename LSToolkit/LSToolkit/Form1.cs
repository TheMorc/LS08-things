using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.IO;
using System.Xml;
using PasteBin;

namespace LSToolkit
{
    
    public partial class Form1 : Form
    {
        XmlDocument gamexml = new XmlDocument();
        XmlDocument savegamesxml = new XmlDocument();
        XmlNode node;
            
        public Form1()
        {
            InitializeComponent();
        }

        //functions for savegames xml
        public CheckBox returncheckbox(int i)
        {
            if (i == 6)
                return sg6;
            else if (i == 5)
                return sg5;
            else if (i == 4)
                return sg4;
            else if (i == 3)
                return sg3;
            else if (i == 2)
                return sg2;
            else if (i == 1)
                return sg1;
            else
                return null;
        }
        public TextBox returntextbox(int i, int which)
        {
            if (which == 0)
            {
                if (i == 6)
                    return t6;
                else if (i == 5)
                    return t5;
                else if (i == 4)
                    return t4;
                else if (i == 3)
                    return t3;
                else if (i == 2)
                    return t2;
                else if (i == 1)
                    return t1;
            }else if(which == 1){
                if (i == 6)
                    return m6;
                else if (i == 5)
                    return m5;
                else if (i == 4)
                    return m4;
                else if (i == 3)
                    return m3;
                else if (i == 2)
                    return m2;
                else if (i == 1)
                    return m1;
            }
            return null;
        }

        //savegamesxml functions
        public void reloadsavegamesxml()
        {
            try
            {
                savegamesxml.Load(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/savegames.xml");
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during loading the savegames.xml.. (This should not happen in any situation whatsoever!)\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }

            for (int i = 1; i <= 6; i++)
            {
                try
                {
                    node = savegamesxml.DocumentElement.SelectSingleNode("/savegames/quickPlay/savegame" + i);
                    if (node.Attributes["valid"].InnerText == "false")
                        returncheckbox(i).Checked = false;
                    else
                        returncheckbox(i).Checked = true;

                    returntextbox(i, 0).Text = node.Attributes["dayTime"].InnerText;
                    returntextbox(i, 1).Text = node.Attributes["money"].InnerText;
                }
                catch (Exception exc)
                {
                    MessageBox.Show("An error happened during retrieving savegame" + i + " value from game.xml.. (This should not happen in any situation whatsoever!)\n\n" + exc.Message,
                        "LS2008 Toolkit",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error);
                }
            }

        }
        public void savesavegamesxml()
        {
            for (int i = 1; i <= 6; i++)
            {
                    node = savegamesxml.DocumentElement.SelectSingleNode("/savegames/quickPlay/savegame" + i);
                    if (returncheckbox(i).Checked)
                        node.Attributes["valid"].InnerText = "true";
                    else
                        node.Attributes["valid"].InnerText = "false";

                    node.Attributes["dayTime"].InnerText = returntextbox(i, 0).Text;
                    node.Attributes["money"].InnerText = returntextbox(i,1).Text;
            }
            try
            {
                if (File.Exists(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/savegames.xml.bak"))
                {
                    File.Delete(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/savegames.xml.bak");
                }
                System.IO.File.Copy(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/savegames.xml", Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/savegames.xml.bak");
                savegamesxml.Save(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/savegames.xml");
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during making a backup and saving the savegames.xml..\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }

        //gamexml functions
        public void reloadgamexml()
        {
            
            textBox1.Text = Properties.Settings.Default.gameFolder;
            Properties.Settings.Default.Save();
            try
            {
                gamexml.Load(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/game.xml");
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during loading the game.xml.. (This should not happen in any situation whatsoever!)\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }

            try
            {
                node = gamexml.DocumentElement.SelectSingleNode("/game/graphic/display/vsync");
                if (node.InnerText == "false")
                    vsync.Checked = false;
                else
                    vsync.Checked = true;
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during retrieving vsync value from game.xml.. (This should not happen in any situation whatsoever!)\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }

            try
            {
                node = gamexml.DocumentElement.SelectSingleNode("/game/graphic/display/fullscreen");
                if (node.InnerText == "false")
                    fullscreen.Checked = false;
                else
                    fullscreen.Checked = true;
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during retrieving fullscreen value from game.xml.. (This should not happen in any situation whatsoever!)\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }

            try
            {
                node = gamexml.DocumentElement.SelectSingleNode("/game/audio/music");
                if (node.Attributes["enable"].InnerText == "false")
                    music.Checked = false;
                else
                    music.Checked = true;
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during retrieving music value from game.xml.. (This should not happen in any situation whatsoever!)\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }

            try
            {
                node = gamexml.DocumentElement.SelectSingleNode("/game/audio/sfx");
                if (node.Attributes["enable"].InnerText == "false")
                    sfx.Checked = false;
                else
                    sfx.Checked = true;
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during retrieving sfx value from game.xml.. (This should not happen in any situation whatsoever!)\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }

            try
            {
                bool verbose, file, console, controls = false;
                node = gamexml.DocumentElement.SelectSingleNode("/game/logging");
                if (node.Attributes["verbose"].InnerText == "false")
                    verbose = false;
                else
                    verbose = true;

                node = gamexml.DocumentElement.SelectSingleNode("/game/logging/file");
                if (node.Attributes["enable"].InnerText == "false")
                    file = false;
                else
                    file = true;

                node = gamexml.DocumentElement.SelectSingleNode("/game/logging/console");
                if (node.Attributes["enable"].InnerText == "false")
                    console = false;
                else
                    console = true;

                node = gamexml.DocumentElement.SelectSingleNode("/game/development/controls");
                if (node.InnerText == "false")
                    controls = false;
                else
                    controls = true;

                if (verbose && file && console && controls)
                {
                    enablelog.Checked = true;
                    loglabel.Text = "(Logging is enabled)";
                    loginfo.Visible = false;
                    try
                    {
                            textBox18.Text = System.IO.File.ReadAllText(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/output.log");
                    }
                    catch (Exception exc)
                    {
                        MessageBox.Show("An error happened during reading the output.log.. Maybe you haven't run the game since this has been enabled?\nPossible solution: Open the game and close it.\n\n" + exc.Message,
                            "LS2008 Toolkit",
                            MessageBoxButtons.OK,
                            MessageBoxIcon.Error);
                    }
                }
                else
                {
                    enablelog.Checked = false;
                    loglabel.Text = "(Logging is not enabled)";
                    loginfo.Visible = true; 
                    textBox18.Text = "";
                }
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during retrieving log value from game.xml.. (This should not happen in any situation whatsoever!)\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }

            
        }
        public void savegamexml() {
            node = gamexml.DocumentElement.SelectSingleNode("/game/graphic/display/vsync");
            if (vsync.Checked)
                node.InnerText = "true";
            else
                node.InnerText = "false";

            node = gamexml.DocumentElement.SelectSingleNode("/game/graphic/display/fullscreen");
            if (fullscreen.Checked)
                node.InnerText = "true";
            else
                node.InnerText = "false";

            node = gamexml.DocumentElement.SelectSingleNode("/game/audio/music");
            if (music.Checked)
                node.Attributes["enable"].InnerText = "true";
            else
                node.Attributes["enable"].InnerText = "false";

            node = gamexml.DocumentElement.SelectSingleNode("/game/audio/sfx");
            if (sfx.Checked)
                node.Attributes["enable"].InnerText = "true";
            else
                node.Attributes["enable"].InnerText = "false";

            if (enablelog.Checked)
            {
                node = gamexml.DocumentElement.SelectSingleNode("/game/logging");
                node.Attributes["verbose"].InnerText = "true";
                node = gamexml.DocumentElement.SelectSingleNode("/game/logging/file");
                node.Attributes["enable"].InnerText = "true";
                node = gamexml.DocumentElement.SelectSingleNode("/game/logging/console");
                node.Attributes["enable"].InnerText = "true";
                node = gamexml.DocumentElement.SelectSingleNode("/game/development/controls");
                node.InnerText = "true";
            }
            else
            {
                node = gamexml.DocumentElement.SelectSingleNode("/game/logging");
                node.Attributes["verbose"].InnerText = "false";
                node = gamexml.DocumentElement.SelectSingleNode("/game/logging/file");
                node.Attributes["enable"].InnerText = "false";
                node = gamexml.DocumentElement.SelectSingleNode("/game/logging/console");
                node.Attributes["enable"].InnerText = "false";
                node = gamexml.DocumentElement.SelectSingleNode("/game/development/controls");
                node.InnerText = "false";
            }

            try
            {
                if (File.Exists(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/game.xml.bak"))
                {
                    File.Delete(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/game.xml.bak");
                }
                System.IO.File.Copy(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/game.xml", Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/game.xml.bak");
                gamexml.Save(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/game.xml");
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during making a backup and saving the game.xml..\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            //open a nice messagebox on the first open
            if(Properties.Settings.Default.firstOpen){
                MessageBox.Show("Welcome to the LS2008 Toolkit! I hope this small app will help you!\n\nMade with <3 by Morc",
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
                Properties.Settings.Default.firstOpen = false;
            }

            //reload all values from game.xml and savegames.xml
            reloadgamexml();
            reloadsavegamesxml();
            
        }

        //open komeos site button
        private void linkLabel1_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e)
        {
            System.Diagnostics.Process.Start("https://komeo.xyz/ls2009mods/");
        }

        //open my site button
        private void linkLabel2_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e)
        {
            System.Diagnostics.Process.Start("http://176.101.178.133:370/");
        }

        //open savegame folder button
        private void button3_Click(object sender, EventArgs e)
        {
            try
            {
                System.Diagnostics.Process.Start(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008");
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during opening the savegame folder.. (This should not happen in any situation!)\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error); 
            }
        }

        //open game folder button
        private void button4_Click(object sender, EventArgs e)
        {
            try
            {
                System.Diagnostics.Process.Start(textBox1.Text);
            }
            catch (SystemException)
            {
                MessageBox.Show("Your LS2008 folder is not correct. Please check your settings.",
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during opening the game folder..\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }

        //delete app settings button
        private void button5_Click(object sender, EventArgs e)
        {
            DialogResult question = MessageBox.Show("Are you sure you want to delete the properties of LS2008 Toolkit?",
                "LS2008 Toolkit",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);
            if (question == DialogResult.Yes)
            {
                MessageBox.Show("Deleting settings and exiting..\nBye..",
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
                Properties.Settings.Default.Reset();
                Close();
            }
        }

        //change ls folder button
        private void LSfolder_Click(object sender, EventArgs e)
        {
            //change game folder button

            OpenFileDialog openFileDialog1 = new OpenFileDialog
            {
                InitialDirectory = @"C:\Program Files (x86)",
                Title = "Browse LS2008 folder",

                FileName = "FarmingSimulator2008",
                DefaultExt = "exe",
                Filter = "FarmingSimulator2008.exe|FarmingSimulator2008.exe",
                FilterIndex = 2,
                RestoreDirectory = true
            };

            if (openFileDialog1.ShowDialog() == DialogResult.OK)
            {
                textBox1.Text = openFileDialog1.FileName.Replace("FarmingSimulator2008.exe","");
                Properties.Settings.Default.gameFolder = openFileDialog1.FileName.Replace("FarmingSimulator2008.exe", "");
                Properties.Settings.Default.Save();
            }
        }

        //generate error report button
        private void button1_Click(object sender, EventArgs e)
        {
            //generate report button
            if (loglabel.Text == "(Logging is not enabled)")
            {
                MessageBox.Show("Cannot proceed, logging needs to be enabled!",
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return;
            }

            if (Tmod.Text == "")
            {
                MessageBox.Show("Cannot proceed, mod name is empty!",
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return;
            }

            if (Tuser.Text == ""){
                MessageBox.Show("Cannot proceed, Discord nickname is empty!",
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return;
            }

            if (Tproblem.Text == ""){
                MessageBox.Show("Cannot proceed, problem overview is empty!",
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return;
            }

            //creating the text output for pastebin and the file output
            string logoutput, modLink, fileOutput, fileName = "";
            logoutput = "";

            if (Tlink.Text == "")
                modLink = "";
            else
                modLink = "\r\nLink to the mod: " + Tlink.Text;
            try
            {
                logoutput = System.IO.File.ReadAllText(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/output.log");
            }
            catch (Exception exc)
            {
                MessageBox.Show("Cannot proceed with sending the error report as an error happened during reading the output.log.. Maybe you haven't run the game since this has been enabled?\nPossible solution: Open the game, wait until the problem happens and close it.\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }

            fileName = "LS2008 Error Report - " + Tuser.Text;
            fileOutput = "Error report by: " + Tuser.Text + "\r\nProblem with: " + Tmod.Text + modLink + "\r\nProblem overview: " + Tproblem.Text + "\r\n\r\n--------------------------\r\n     GAME LOG OUTPUT     \r\n--------------------------\r\n" + logoutput;

            DialogResult question = MessageBox.Show("Do you want to send the log to pastebin or to save it to a file?\n\nSelect Yes for PasteBin, No for local file and cancel to cancel sending a error report.",
                "LS2008 Toolkit",
                MessageBoxButtons.YesNoCancel,
                MessageBoxIcon.Question);
            if (question == DialogResult.Yes)
            {
                var client = new PasteBinClient("axbfYcaOMTKf4ZjTmow_zxi6n5-Bg2Mv");
                client.Login("LSToolkit", "<redacted>");

                var entry = new PasteBinEntry
                {
                    Title = fileName,
                    Text = fileOutput,
                    Expiration = PasteBinExpiration.Never,
                    Private = false
                };

                string pasteUrl = client.Paste(entry);

                try
                {
                    System.Diagnostics.Process.Start(pasteUrl);
                }
                catch (Exception exc)
                {
                    MessageBox.Show("An error happened during opening the pastebin log.. \n\n" + exc.Message,
                        "LS2008 Toolkit",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error);
                }
            }
            else if (question == DialogResult.No)
            {
                SaveFileDialog saveFile = new SaveFileDialog()
                    {
                        AddExtension = true, 
                        FileName = fileName, 
                        InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.Desktop),
                        RestoreDirectory = true,
                        OverwritePrompt = true,
                        Title = "Select a folder to save the log",
                        Filter = "Log files|*.log",
                        DefaultExt = "log"
                    };

                if (saveFile.ShowDialog() == DialogResult.OK)
                {
                    StreamWriter writer = new StreamWriter(saveFile.OpenFile());
                    writer.WriteLine(fileOutput);
                    writer.Dispose();
                    writer.Close();
                }

            }
            else
            {
                //user clicked the cancel button, canceling the operation
                return;
            }

        }

        //save all changes button
        private void button2_Click(object sender, EventArgs e)
        {
            //save all changes button
            Properties.Settings.Default.Save();
            savegamexml();
            reloadgamexml();
            savesavegamesxml();
            reloadsavegamesxml();

        }

        //backup game data button
        private void button6_Click(object sender, EventArgs e)
        {
            DialogResult question = MessageBox.Show("Are you sure you want create a backup of your LS2008 files?\nThis creates a folder in a selected folder and makes a backup of careerVehicles.xml and vehicleTypes.xml from the game folder and game.xml, savegames.xml and the savegame folders from the savegames folder.",
                "LS2008 Toolkit",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);
            if (question == DialogResult.Yes)
            {
                FolderBrowserDialog folder = new FolderBrowserDialog
                {
                    RootFolder = Environment.SpecialFolder.Desktop,
                    Description = "Select a folder for the backup"
                };

                if (folder.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        if (Directory.Exists(folder.SelectedPath + "/LSToolkit_Backup"))
                        {
                            DialogResult question2 = MessageBox.Show("Looks like the backup is already there. Do you want to overwrite it?\n\nSelecting No cancels the backup!",
                                "LS2008 Toolkit",
                                MessageBoxButtons.YesNo,
                                MessageBoxIcon.Question);
                            if (question2 == DialogResult.Yes)
                            {
                                Directory.Delete(folder.SelectedPath + "/LSToolkit_Backup", true);
                            }
                            else
                                return;
                            
                        }


                        System.IO.Directory.CreateDirectory(folder.SelectedPath + "/LSToolkit_Backup");

                        System.IO.File.Copy(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/game.xml", folder.SelectedPath + "/LSToolkit_Backup/game.xml");
                        System.IO.File.Copy(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/savegames.xml", folder.SelectedPath + "/LSToolkit_Backup/savegames.xml");

                        System.IO.File.Copy(Properties.Settings.Default.gameFolder + "data/careerVehicles.xml", folder.SelectedPath + "/LSToolkit_Backup/careerVehicles.xml");
                        System.IO.File.Copy(Properties.Settings.Default.gameFolder + "data/vehicleTypes.xml", folder.SelectedPath + "/LSToolkit_Backup/vehicleTypes.xml");

                        for (int i = 1; i <= 6; i++)
                        {
                            System.IO.Directory.CreateDirectory(folder.SelectedPath + "/LSToolkit_Backup/savegame" + i);
                            foreach(var file in Directory.GetFiles(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/savegame" + i))
                                System.IO.File.Copy(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/savegame" + i + "/" + Path.GetFileName(file), folder.SelectedPath + "/LSToolkit_Backup/savegame"+i+"/"+ Path.GetFileName(file));
                        
                        }
                    }
                    catch (Exception exc)
                    {
                        MessageBox.Show("An error happened during backuping your game.. \n\n" + exc.Message,
                            "LS2008 Toolkit",
                            MessageBoxButtons.OK,
                            MessageBoxIcon.Error);
                    }
                }
            }
        }

        //open output log button
        private void button7_Click(object sender, EventArgs e)
        {
            try
            {
                System.Diagnostics.Process.Start(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/output.log");
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during opening the log.. (This should not happen if you have logging enabled!)\nPossible solution: Open game and close it.\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }

        //reload log button
        private void button10_Click(object sender, EventArgs e)
        {
            try
            {
                textBox18.Text = System.IO.File.ReadAllText(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "/FarmingSimulator2008/output.log");
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during reading the output.log.. Maybe you haven't run the game since this has been enabled?\nPossible solution: Open the game and close it.\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }

        //reload all button
        private void button9_Click(object sender, EventArgs e)
        {
            reloadgamexml();
            reloadsavegamesxml();
        }

        //open game button
        private void button11_Click(object sender, EventArgs e)
        {
            try
            {
                System.Diagnostics.Process.Start(Properties.Settings.Default.gameFolder + "FarmingSimulator2008.exe");
            }
            catch (Exception exc)
            {
                MessageBox.Show("An error happened during opening the game.. (This should not happen in any situation!)\n\n" + exc.Message,
                    "LS2008 Toolkit",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }

        //error report button in output log tab
        private void button12_Click(object sender, EventArgs e)
        {
            tabs.SelectedTab = tabs.TabPages[1];
        }

        //open standalone time calculator
        private void button13_Click(object sender, EventArgs e)
        {
            Form2 timecalc = new Form2();
            timecalc.button1.Visible = false;
            timecalc.ShowDialog();
        }

        //savegame time buttons
        public void timecalc(TextBox tBOX, int i)
        {
            Form2 timecalc = new Form2();
            timecalc.numericUpDown1.Value = Convert.ToDecimal(tBOX.Text);
            timecalc.sg = i;
            timecalc.ShowDialog(this);
        }
        private void tb1_Click(object sender, EventArgs e)
        {
            timecalc(t1, 1);
        }
        private void button14_Click(object sender, EventArgs e)
        {
            timecalc(t2, 2);
        }
        private void button15_Click(object sender, EventArgs e)
        {
            timecalc(t3, 3);
        }
        private void button16_Click(object sender, EventArgs e)
        {
            timecalc(t4, 4);
        }
        private void button17_Click(object sender, EventArgs e)
        {
            timecalc(t5, 5);
        }
        private void button18_Click(object sender, EventArgs e)
        {
            timecalc(t6, 6);
        }
    }
}
