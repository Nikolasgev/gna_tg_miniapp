import React from 'react'
import { Coffee, Mail, Phone, MapPin } from 'lucide-react'

const Footer = () => {
  return (
    <footer className="bg-gray-900 text-white py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid md:grid-cols-4 gap-8 mb-8">
          {/* Logo */}
          <div>
            <div className="flex items-center gap-2 mb-4">
              <div className="w-10 h-10 bg-gradient-to-br from-coffee-700 via-coffee-800 to-amber-900 rounded-lg flex items-center justify-center">
                <Coffee className="w-6 h-6 text-white" />
              </div>
              <span className="text-xl font-bold">CoffeeShop</span>
            </div>
            <p className="text-gray-400 text-sm">
              Ваша кофейня в Telegram. Продавайте кофе и десерты через удобное Mini App приложение.
            </p>
          </div>

          {/* Links */}
          <div>
            <h3 className="font-semibold mb-4">Продукт</h3>
            <ul className="space-y-2 text-gray-400 text-sm">
              <li>
                <a href="#features" className="hover:text-white transition-colors">
                  Возможности
                </a>
              </li>
              <li>
                <a href="#menu" className="hover:text-white transition-colors">
                  Меню
                </a>
              </li>
              <li>
                <a href="#pricing" className="hover:text-white transition-colors">
                  Тарифы
                </a>
              </li>
              <li>
                <a href="#how-it-works" className="hover:text-white transition-colors">
                  Как это работает
                </a>
              </li>
            </ul>
          </div>

          {/* Company */}
          <div>
            <h3 className="font-semibold mb-4">Компания</h3>
            <ul className="space-y-2 text-gray-400 text-sm">
              <li>
                <a href="#" className="hover:text-white transition-colors">
                  О нас
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-white transition-colors">
                  Блог
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-white transition-colors">
                  Карьера
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-white transition-colors">
                  Контакты
                </a>
              </li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h3 className="font-semibold mb-4">Контакты</h3>
            <ul className="space-y-3 text-gray-400 text-sm">
              <li className="flex items-center gap-2">
                <Mail className="w-4 h-4" />
                hello@coffeeshop.ru
              </li>
              <li className="flex items-center gap-2">
                <Phone className="w-4 h-4" />
                +7 (999) 123-45-67
              </li>
              <li className="flex items-center gap-2">
                <MapPin className="w-4 h-4" />
                Москва, Россия
              </li>
            </ul>
          </div>
        </div>

        <div className="border-t border-gray-800 pt-8 text-center text-gray-400 text-sm">
          <p>© 2024 CoffeeShop. Все права защищены.</p>
        </div>
      </div>
    </footer>
  )
}

export default Footer

