using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;

using Borgstrup.EditableTextBlock;

using D = System.Collections.Generic.Dictionary<string, object>;

namespace ObjectRPC.WPF
{
    class UIElementFacet : Facet<UIElement>
    {
        public UIElementFacet(Entity entity, UIElement obj)
            : base(entity, obj)
        {
        }

        public bool Visible
        {
            set { obj.Visibility = value ? Visibility.Visible : Visibility.Hidden; }
        }
        public bool Enabled
        {
            set { obj.IsEnabled = value; }
        }
    }

    class TextBlockFacet : Facet<TextBlock>
    {
        public TextBlockFacet(Entity entity, TextBlock obj)
            : base(entity, obj)
        {
        }

        public string Text
        {
            set
            {
                obj.Text = value;
            }
        }
    }

    class ButtonFacet : Facet<Button>
    {
        public ButtonFacet(Entity entity, Button obj)
            : base(entity, obj)
        {
            obj.Click += OnClick;
        }

        public string Label
        {
            set
            {
                obj.Content = value;
            }
        }

        private void OnClick(object sender, RoutedEventArgs e)
        {
            entity.SendUpdate(new D{ {"click", true } });
        }
    }

    class CheckBoxFacet : Facet<CheckBox>
    {
        public CheckBoxFacet(Entity entity, CheckBox obj)
            : base(entity, obj)
        {
            obj.Click += OnClick;
        }

        public string Label
        {
            set { obj.Content = value; }
        }

        public bool Value
        {
            set { obj.IsChecked = value; }
        }

        private void OnClick(object sender, RoutedEventArgs e)
        {
            entity.SendUpdate(new D{ { "value", obj.IsChecked } });
        }
    }

    class TextBoxFacet : Facet<TextBox>
    {
        private bool isBeingChangedByUser = false;
        private bool isBeingChangedProgramatically = false;

        public TextBoxFacet(Entity entity, TextBox obj)
            : base(entity, obj)
        {
            obj.TextChanged += OnTextChanged;
            obj.LostFocus   += OnLostFocus;
        }

        public string Text
        {
            set
            {
                if (!isBeingChangedByUser)
                {
                    isBeingChangedProgramatically = true;
                    obj.Text = value;
                    isBeingChangedProgramatically = false;
                }
            }
        }

        private void OnTextChanged(object sender, RoutedEventArgs e)
        {
            if (!isBeingChangedProgramatically)
            {
                isBeingChangedByUser = true;
                entity.SendUpdate(new D{ { "text", obj.Text } });
            }
        }

        private void OnLostFocus(object sender, RoutedEventArgs e)
        {
            isBeingChangedByUser = false;
        }
    }


    class TreeViewFacet : Facet<TreeView>
    {
        private IList<object> data;
        private bool isTreeViewUpdateInProgress = false;
        private bool isInEditMode = false;
        private EditableTextBlock currentETB;

        public TreeViewFacet(Entity entity, TreeView obj)
            : base(entity, obj)
        {
            obj.MouseDoubleClick    += OnMouseDoubleClick;
            obj.SelectedItemChanged += OnSelectedItemChanged;
        }

        public string SelectedId
        {
            get
            {
                var selectedTVI = (TreeViewItem)obj.SelectedItem;
                return (string)((selectedTVI != null) ? selectedTVI.Tag : null);
            }
        }

        private bool IsInEditMode
        {
            get
            {
                return isInEditMode;
            }
            set
            {
                // Make sure that the SelectedItem is actually a TreeViewItem
                // and not null or something else
                if (obj.SelectedItem is TreeViewItem)
                {
                    TreeViewItem tvi = obj.SelectedItem as TreeViewItem;

                    // Also make sure that the TreeViewItem
                    // uses an EditableTextBlock as its header
                    if (tvi.Header is EditableTextBlock)
                    {
                        EditableTextBlock etb = tvi.Header as EditableTextBlock;

                        // Finally make sure that we are
                        // allowed to edit the TextBlock
                        if (etb.IsEditable)
                        {
                            etb.IsInEditMode = value;
                            if (value && !isInEditMode) // we are starting edit mode
                            {
                                currentETB = etb;
                                currentETB.TextChanged += currentETB_TextChanged;
                                currentETB.LostFocus += currentETB_LostFocus;
                            }
                            isInEditMode = value;
                        }
                    }
                }
            }
        }

        void currentETB_TextChanged(object sender, TextChangedEventArgs e)
        {
            //TODO: add facet for items; 
            entity.SendUpdate(new D { { "#" + SelectedId, new D { { "text", currentETB.Text } } } });
            //Console.WriteLine("#" + SelectedId);
        }

        //TODO: implement event for switching edit mode and use it instead
        void currentETB_LostFocus(object sender, RoutedEventArgs e)
        {
            currentETB.LostFocus   -= currentETB_LostFocus;
            currentETB.TextChanged -= currentETB_TextChanged;
            currentETB = null;
        }

        private void Fill(ItemCollection items, IList<object> data, string oldSelectedId, out TreeViewItem newSelectedTVI)
        {
            newSelectedTVI = null;
            foreach (var itemDataRaw in data)
            {
                var itemData = (Dictionary<string, object>)itemDataRaw;
                string id = (string)itemData["id"];
                string text = (string)itemData["text"];
                IList<object> children = (itemData.ContainsKey("children") ? (IList<object>)itemData["children"] : null);
                bool editable = (itemData.ContainsKey("editable") ? (bool)itemData["editable"] : false);

                var tvi = new TreeViewItem();

                if ((id == oldSelectedId) && isInEditMode)
                    tvi.Header = currentETB;
                else
                    tvi.Header = new EditableTextBlock(text, editable);

                tvi.Tag = id;
                items.Add(tvi);

                if (id == oldSelectedId)
                    newSelectedTVI = tvi;

                if (children != null)
                {
                    TreeViewItem childNewSelectedTVI;
                    Fill(tvi.Items, children, oldSelectedId, out childNewSelectedTVI);
                    if (childNewSelectedTVI != null)
                        newSelectedTVI = childNewSelectedTVI;
                }
            }
        }

        private void OnMouseDoubleClick(object sender, RoutedEventArgs e)
        {
            IsInEditMode = true;
        }

        public IList<object> Data
        {
            set
            {
                data = value;

                var items = obj.Items;

                TreeViewItem newSelectedTVI = null;

                isTreeViewUpdateInProgress = true;
                string oldSelectedId = SelectedId;
                items.Clear();
                Fill(items, data, oldSelectedId, out newSelectedTVI);

                if (oldSelectedId != null)
                    if (newSelectedTVI == null )
                    {
                        isTreeViewUpdateInProgress = false;
                        OnSelectedItemChanged(null, null); // need to reset view
                    }
                    else
                    {
                        SelectItem(newSelectedTVI);
                        isTreeViewUpdateInProgress = false;
                    }
                else
                    isTreeViewUpdateInProgress = false;
            }
        }

        private void SelectItemHelper(TreeViewItem item)
        {
            if (item == null)
                return;
            SelectItemHelper(item.Parent as TreeViewItem);
            if (!item.IsExpanded)
            {
                item.IsExpanded = true;
                item.UpdateLayout();
            }
        }
        private void SelectItem(TreeViewItem item) // QND solution
        {
            SelectItemHelper(item.Parent as TreeViewItem);
            item.IsSelected = true;
        }

        private void OnSelectedItemChanged(object sender, RoutedPropertyChangedEventArgs<object> e)
        {
            if (!isTreeViewUpdateInProgress)
                entity.SendUpdate(new D{ { "selectedId", SelectedId } });
        }
    }

    public static class UIFacets
    {
        public static void Register(RootEntity rpc)
        {
            rpc.Register(typeof(UIElement), typeof(UIElementFacet));
            rpc.Register(typeof(TextBlock), typeof(TextBlockFacet));
            rpc.Register(typeof(Button), typeof(ButtonFacet));
            rpc.Register(typeof(TreeView), typeof(TreeViewFacet));
            rpc.Register(typeof(CheckBox), typeof(CheckBoxFacet));
            rpc.Register(typeof(TextBox), typeof(TextBoxFacet));
        }
    }
}
