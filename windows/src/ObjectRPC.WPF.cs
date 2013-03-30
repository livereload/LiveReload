using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;

using Borgstrup.EditableTextBlock;

using D = System.Collections.Generic.Dictionary<string, object>;
using MahApps.Metro.Controls;

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

    class MetroToggleSwitchButtonFacet : Facet<ToggleSwitchButton>
    {
        public MetroToggleSwitchButtonFacet(Entity entity, ToggleSwitchButton obj)
            : base(entity, obj) {
            obj.Checked += OnClick;
            obj.Unchecked += OnClick;
        }

        public string Label {
            set { obj.Content = value; }
        }

        public bool Value {
            set { obj.IsChecked = value; }
        }

        private void OnClick(object sender, RoutedEventArgs e) {
            entity.SendUpdate(new D { { "value", obj.IsChecked } });
        }
    }

    class ToggleSwitchFacet : Facet<ToggleSwitch>
    {
        public ToggleSwitchFacet(Entity entity, ToggleSwitch obj)
            : base(entity, obj) {
            obj.Click += OnClick;
        }

        public string Label {
            set { obj.Content = value; }
        }

        public bool Value {
            set { obj.IsChecked = value; }
        }

        private void OnClick(object sender, RoutedEventArgs e) {
            entity.SendUpdate(new D { { "value", obj.IsChecked } });
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

    public class TreeViewItemViewModel
    {
        public string Id { get; set; }
        public string Text { get; set; }
        public bool Editable { get; set; }
        public IList<TreeViewItemViewModel> Children { get; set; }
    }

    class TreeViewFacet : Facet<TreeView>
    {
        private bool isTreeViewUpdateInProgress = false;

        private ObservableCollection<TreeViewItemViewModel> items = new ObservableCollection<TreeViewItemViewModel>();

        public TreeViewFacet(Entity entity, TreeView obj)
            : base(entity, obj)
        {
            //obj.MouseDoubleClick    += OnMouseDoubleClick;
            obj.SelectedItemChanged += OnSelectedItemChanged;
            obj.ItemsSource = items;
        }

        public string SelectedId
        {
            get
            {
                var selectedTVI = (TreeViewItemViewModel)obj.SelectedItem;
                return (string)((selectedTVI != null) ? selectedTVI.Id : null);
            }
        }

        //void currentETB_TextChanged(object sender, TextChangedEventArgs e)
        //{
        //    entity.SendUpdate(new D { { "#" + SelectedId, new D { { "text", currentETB.Text } } } });
        //}

        //void currentETB_LostFocus(object sender, RoutedEventArgs e)
        //{
        //    currentETB.LostFocus   -= currentETB_LostFocus;
        //    currentETB.TextChanged -= currentETB_TextChanged;
        //    currentETB = null;
        //}

        private IList<TreeViewItemViewModel> CreateItems(IList<object> data)
        {
            return data.Select((itemDataRaw) => {
                var itemData = (Dictionary<string, object>)itemDataRaw;
                string id = (string)itemData["id"];
                string text = (string)itemData["text"];
                IList<object> children = (itemData.ContainsKey("children") ? (IList<object>)itemData["children"] : new object[0]);
                bool editable = (itemData.ContainsKey("editable") ? (bool)itemData["editable"] : false);

                return new TreeViewItemViewModel {
                    Id = id,
                    Text = text,
                    Editable = editable,
                    Children = CreateItems(children),
                };
            }).ToList();
        }

        //private void OnMouseDoubleClick(object sender, RoutedEventArgs e)
        //{
        //    IsInEditMode = true;
        //}

        public IList<object> Data
        {
            set
            {
                isTreeViewUpdateInProgress = true;
                try {
                    var items = CreateItems(value);
                    this.items.Clear();
                    foreach (var item in items) {
                        this.items.Add(item);
                    }
                } finally {
                    isTreeViewUpdateInProgress = false;
                }
            }
        }

        //private void SelectItemHelper(TreeViewItem item)
        //{
        //    if (item == null)
        //        return;
        //    SelectItemHelper(item.Parent as TreeViewItem);
        //    if (!item.IsExpanded)
        //    {
        //        item.IsExpanded = true;
        //        item.UpdateLayout();
        //    }
        //}
        //private void SelectItem(TreeViewItem item) // QND solution
        //{
        //    SelectItemHelper(item.Parent as TreeViewItem);
        //    item.IsSelected = true;
        //}

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
            rpc.Register(typeof(ToggleSwitch), typeof(ToggleSwitchFacet));
            rpc.Register(typeof(ToggleSwitchButton), typeof(MetroToggleSwitchButtonFacet));
            rpc.Register(typeof(TextBox), typeof(TextBoxFacet));
        }
    }
}
